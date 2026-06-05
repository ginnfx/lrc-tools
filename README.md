# lrc-tools

Terminal lyrics visualizer. Displays word-by-word synced lyrics in your terminal while music plays.

## Requirements

- Linux with MPRIS support (systemd/dbus)
- mpv as your music player
- playerctl, ffmpeg, yt-dlp

## Install

```bash
git clone https://github.com/ginnfx/lrc-tools.git
cd lrc-tools
bash install.sh
source ~/.bashrc
```

## Usage

```bash
# Download a song and fetch its lyrics
ytlyrics "https://youtu.be/..."

# In terminal 1 — play the song
play ~/music/song.mp3

# In terminal 2 — show lyrics
lyrics
```

## Manual workflow

```bash
# Fetch lyrics for all songs in ~/music
lyrics-fetch

# Process into word-level timing
lyrics-process

# Visualize
lyrics
```

## Notes

- Lyrics are sourced from LRCLIB
- Word-level timing is generated from phrase-level LRC files
- Sync offset defaults to 0.5s, adjust with `--offset` if needed
- YouTube downloads require Firefox cookies (`--cookies-from-browser firefox`)
