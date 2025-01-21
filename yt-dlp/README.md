yt-dlp
===========

# Snippets

## Download with filter

```bash
yt-dlp --filter "extension != 'mp4'"
```

## Download with subtitles

```bash
yt-dlp --write-sub --write-auto-sub --sub-lang "en.*"
```

## Create archive file

```bash
yt-dlp --download-archive archive.txt
```

## Avoid hls stream (use https)

```bash
yt-dlp --format-sort=proto:https
```

## Stream to mpv

```bash
yt-dlp -f bestvideo+bestaudio/best -o - "$url" "${ytdlp_options[@]}" | mpv --cache "${mpv_options[@]}" -
```

> [!WARNING]
> Does not work in `powershell` directly because strings get converted to [.NET strings](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_pipelines?view=powershell-7.4#using-native-commands-in-the-pipeline)
> On powershell core `pwsh` v7.4 it may work due to [`PSNativeCommandPreserveBytePipe`](https://learn.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-74?view=powershell-7.4#experimental-features) feature
> but some errors may be expected like pipe halting or broken pipes

