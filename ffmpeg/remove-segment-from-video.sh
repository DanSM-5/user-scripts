#!/usr/bin/env bash
input_file="$1"
output_file="$2"
# Segment from start_point and end_point will be removed from video
start_point="$3"
end_point="$4"

ffmpeg -i "$input_file" -filter_complex \
  "[0:v]trim=duration=$start_point[av];\
  [0:a]atrim=duration=$start_point[aa];\
  [0:v]trim=start=$end_point,setpts=PTS-STARTPTS[bv];\
  [0:a]atrim=start=$end_point,asetpts=PTS-STARTPTS[ba];\
  [av][aa][bv][ba]concat=n=2:v=1:a=1[outv][outa]" \
  -map '[outv]' -map '[outa]' "$output_file"

# Examples

# Ref: https://superuser.com/a/682534
# ffmpeg -i in.ts -filter_complex \
# "[0:v]trim=duration=30[a]; \
#  [0:v]trim=start=40:end=50,setpts=PTS-STARTPTS[b]; \
#  [a][b]concat[c]; \
#  [0:v]trim=start=80,setpts=PTS-STARTPTS[d]; \
#  [c][d]concat[out1]" -map [out1] out.ts
#
# ffmpeg -i utv.ts -filter_complex \
# "[0:v]trim=duration=30[av];[0:a]atrim=duration=30[aa];\
#  [0:v]trim=start=40:end=50,setpts=PTS-STARTPTS[bv];\
#  [0:a]atrim=start=40:end=50,asetpts=PTS-STARTPTS[ba];\
#  [av][bv]concat[cv];[aa][ba]concat=v=0:a=1[ca];\
#  [0:v]trim=start=80,setpts=PTS-STARTPTS[dv];\
#  [0:a]atrim=start=80,asetpts=PTS-STARTPTS[da];\
#  [cv][dv]concat[outv];[ca][da]concat=v=0:a=1[outa]" -map [outv] -map [outa] out.ts

# Ref: https://superuser.com/a/1498811
# For each input, define a A/V pair:
#
# //Input1:
# [0:v]trim=start=10:end=20,setpts=PTS-STARTPTS,format=yuv420p[0v];
# [0:a]atrim=start=10:end=20,asetpts=PTS-STARTPTS[0a];
# //Input2:
# [0:v]trim=start=30:end=40,setpts=PTS-STARTPTS,format=yuv420p[1v];
# [0:a]atrim=start=30:end=40,asetpts=PTS-STARTPTS[1a];
# //Input3:
# [0:v]trim=start=30:end=40,setpts=PTS-STARTPTS,format=yuv420p[2v];
# [0:a]atrim=start=30:end=40,asetpts=PTS-STARTPTS[2a];
# Define as many pairs as you need, then concat them all in one pass, where n=total input count.
#
# [0v][0a][1v][1a][2v][2a]concat=n=3:v=1:a=1[outv][outa] -map [outv] -map [outa] out.mp4
# This can easily be constructed in a loop.
#
# A complete command that uses 2 inputs might look like this:
#
# ffmpeg -i in.mp4 -filter_complex 
# [0:v]trim=start=10.0:end=15.0,setpts=PTS-STARTPTS,format=yuv420p[0v];
# [0:a]atrim=start=10.0:end=15.0,asetpts=PTS-STARTPTS[0a];
# [0:v]trim=start=65.0:end=70.0,setpts=PTS-STARTPTS,format=yuv420p[1v];
# [0:a]atrim=start=65.0:end=70.0,asetpts=PTS-STARTPTS[1a];[0v][0a][1v]
# [1a]concat=n=2:v=1:a=1[outv][outa] -map [outv] -map [outa] out.mp4
