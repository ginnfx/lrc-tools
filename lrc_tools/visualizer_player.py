"""
Media player integration using playerctl
Handles communication with media players via MPRIS
"""
import subprocess
from pathlib import Path
from typing import Optional, Tuple

# Cache the instance name briefly to avoid calling playerctl -l on every single call
_cached_instance: Optional[str] = None
_cache_time: float = 0

def _find_music_instance() -> Optional[str]:
    """
    Find the mpv instance playing a local audio file.
    Checks all mpv instances and returns the one with a file:// URL.
    Falls back to 'mpv' if only one instance exists.
    """
    import time
    global _cached_instance, _cache_time

    now = time.time()
    if _cached_instance and (now - _cache_time) < 2.0:
        return _cached_instance

    try:
        result = subprocess.run(
            ['playerctl', '-l'],
            capture_output=True, text=True, timeout=0.5
        )
        if result.returncode != 0:
            return None

        instances = [
            i.strip() for i in result.stdout.strip().splitlines()
            if i.strip().startswith('mpv')
        ]

        if not instances:
            return None

        if len(instances) == 1:
            _cached_instance = instances[0]
            _cache_time = now
            return _cached_instance

        # Multiple mpv instances — find the one playing a local file
        for inst in instances:
            url_result = subprocess.run(
                ['playerctl', '-p', inst, 'metadata', '--format', '{{xesam:url}}'],
                capture_output=True, text=True, timeout=0.5
            )
            if url_result.returncode == 0 and url_result.stdout.strip().startswith('file://'):
                _cached_instance = inst
                _cache_time = now
                return inst

    except Exception:
        pass

    return None


def _player_arg() -> list:
    """Get the playerctl -p argument for the music instance."""
    inst = _find_music_instance()
    if inst:
        return ['-p', inst]
    return ['-p', 'mpv']


def get_position() -> Optional[float]:
    """
    Get current playback position in seconds.

    Returns:
        Current position in seconds, or None if unavailable
    """
    try:
        result = subprocess.run(
            ['playerctl'] + _player_arg() + ['position'],
            capture_output=True,
            text=True,
            timeout=0.5
        )
        return float(result.stdout.strip()) if result.returncode == 0 else None
    except Exception:
        return None


def get_track() -> Optional[Tuple[str, str]]:
    """
    Get currently playing track information.

    Returns:
        Tuple of (artist, title), or None if unavailable
    """
    try:
        result = subprocess.run(
            ['playerctl'] + _player_arg() + ['metadata', '--format', '{{artist}}|||{{title}}'],
            capture_output=True,
            text=True,
            timeout=0.5
        )
        if result.returncode == 0:
            parts = result.stdout.strip().split('|||')
            return (parts[0], parts[1]) if len(parts) == 2 else None
    except Exception:
        return None


def get_status() -> Optional[str]:
    """
    Get current playback status.

    Returns:
        Status string ('Playing', 'Paused', 'Stopped'), or None if unavailable
    """
    try:
        result = subprocess.run(
            ['playerctl'] + _player_arg() + ['status'],
            capture_output=True,
            text=True,
            timeout=0.5
        )
        return result.stdout.strip() if result.returncode == 0 else None
    except Exception:
        return None


def get_audio_file_info() -> Optional[Path]:
    """
    Get currently playing audio file path.

    Returns:
        Path to audio file, or None if unavailable
    """
    try:
        result = subprocess.run(
            ['playerctl'] + _player_arg() + ['metadata', '--format', '{{xesam:url}}'],
            capture_output=True,
            text=True,
            timeout=0.5
        )
        if result.returncode == 0:
            url = result.stdout.strip()
            if url.startswith('file://'):
                return Path(url[7:])
    except Exception:
        pass
    return None


def is_paused() -> bool:
    """
    Check if playback is currently paused.

    Returns:
        True if paused, False otherwise
    """
    status = get_status()
    return status == 'Paused' if status else False


def is_playing() -> bool:
    """
    Check if playback is currently active.

    Returns:
        True if playing, False otherwise
    """
    status = get_status()
    return status == 'Playing' if status else False
