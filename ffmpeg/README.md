FFMPEG notes
=========

## Reduce video size

Call ffmpeg with your video without flags for ffmpeg's default optimization

```bash
ffmpeg -i video.mp4 output.mp4
```

- ffmpeg's default behavior is to set the video codec to `libx264` when extension is mp4.
- Codec `libx265` has better compression but it is less accepted.

See more variations in [gist](https://gist.github.com/lukehedger/277d136f68b028e22bed).

## Send video in whatsapp/facebook

To upload videos without issues:

- Video has to be smalled than 25Mb
- Codecs `libx264` and `aac`

```bash
ffmpeg -i video.mp4 -vcodec libx264 -acodec aac out.mp4
```

## Join video and audio

### Simple

Copy audio track from second input into existing tracks in first input

```bash
ffmpeg -i video.mp4 -i audio.mp4 -map 1:a -map 0 -c:v 'h264' -c:a 'aac' output.mp4
```

