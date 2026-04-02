# lrc-tools

Terminal lyrics visualizer and LRC processing suite. Display synchronized lyrics in your terminal while music plays through mpv (or any MPRIS-compatible player).

![Python 3.10+](https://img.shields.io/badge/python-3.10%2B-blue)

## Features

- **lrc-vis** — Real-time synchronized lyrics display in the terminal with custom bitmap fonts
- **lrc-fetch** — Batch download `.lrc` lyrics from LRCLIB (with syncedlyrics fallback)
- **lrc-processor** — Split and convert LRC files to word-level timing (WLRC)

## Dependencies

### System packages

These must be installed separately via your package manager:

- **playerctl** — MPRIS media player control (used to detect currently playing track)
- **ffprobe** (part of ffmpeg) — Audio file duration detection
- **mpv** with MPRIS plugin — Or any MPRIS-compatible music player

#### Arch Linux

```bash
sudo pacman -S playerctl ffmpeg mpv mpv-mpris
```

#### Debian/Ubuntu

```bash
sudo apt install playerctl ffmpeg mpv
# mpv-mpris may need to be built from source:
# https://github.com/hoyon/mpv-mpris
```

### Python packages

Installed automatically via pip. Optional extras provide additional features:

| Package | Required | Purpose |
|---|---|---|
| pyyaml | Yes | Config file parsing |
| mutagen | No | Read embedded audio tags (artist/title) |
| syncedlyrics | No | Fallback lyrics source beyond LRCLIB |

## Installation

```bash
git clone https://github.com/brajanz29/lrc-tools.git
cd lrc-tools
chmod +x install.sh
./install.sh
```

The installer handles everything: system dependencies, Python package, directory setup, config files, and shell aliases. After it finishes, reload your shell and you're good to go.

### Manual installation

If you prefer to do it yourself:

```bash
pip install '.[full]'
```

Then set up the directories and aliases manually (see Configuration below).

## Quick start

Put your music in `~/music`, then:

```bash
lyrics-fetch              # download lyrics for your library
lyrics-process            # process into word-level timing
```

Start playing music in mpv, then in another terminal:

```bash
lyrics                    # show synced lyrics
```

## Custom fonts

You can define custom bitmap fonts in a JSON file and pass them to `lrc-vis`:

```bash
lrc-vis --lrc-dir ~/lyrics --font mini --custom-fonts ~/.config/lrc-tools/custom_fonts.json
```

## Configuration

Create a `config.yaml` to set defaults:

```yaml
processor:
  max_phrase_duration: 2.5
  max_words_per_phrase: 8
  split_on_commas: true

visualizer:
  default_font: block
  refresh_rate: 0.05

puller:
  search_threads: 5
  download_threads: 5
  prefer_synced: true
```

Pass it with `--config path/to/config.yaml` on any command.

## Multiple mpv instances

If you run mpv for both music and video (e.g., watching anime while listening to music), lrc-vis automatically detects and locks onto the mpv instance playing a local audio file, ignoring any streaming video instances.

## License

MIT
