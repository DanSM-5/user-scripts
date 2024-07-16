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

