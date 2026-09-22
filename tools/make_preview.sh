#!/bin/sh
# The two preview videos a portal asks for, cut out of a recording made by tools/demo.gd:
#
#     Godot --path . --write-movie build/preview/raw.avi --fixed-fps 60 \
#         --resolution 720x1280 res://tools/demo.tscn
#     tools/make_preview.sh <seconds-in> [length]
#
# The game is portrait, so the portrait video is simply the recording scaled up. The landscape one
# cannot be: a 9:16 picture in a 16:9 frame leaves two thirds of the frame empty. Rather than bars
# it fills them with the same frame blown up, blurred and darkened, which is what every portrait
# video does on a landscape page - the eye reads it as depth and stays on the middle.
#
# Twenty seconds is the portal's ceiling; this stops a little short of it so no rounding trips it.
set -e
START=${1:?usage: make_preview.sh <seconds-in> [length]}
LENGTH=${2:-19.5}
DIR=$(cd "$(dirname "$0")/.." && pwd)/build/preview
IN="$DIR/work.mp4"
FADE=$(echo "$LENGTH - 0.4" | bc)

ffmpeg -y -v error -ss "$START" -t "$LENGTH" -i "$IN" \
	-vf "scale=1080:1920:flags=neighbor,fade=in:st=0:d=0.3,fade=out:st=$FADE:d=0.4" \
	-af "afade=in:st=0:d=0.3,afade=out:st=$FADE:d=0.4" \
	-c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p -r 60 -c:a aac -b:a 160k -movflags +faststart \
	"$DIR/preview_portrait.mp4"

# neighbor scaling on the middle keeps the pixel art crisp; the background is blurred anyway.
ffmpeg -y -v error -ss "$START" -t "$LENGTH" -i "$IN" \
	-filter_complex "[0:v]split=2[bg][fg]; \
		[bg]scale=1920:-2,crop=1920:1080,boxblur=24:2,eq=brightness=-0.18:saturation=0.7[back]; \
		[fg]scale=-2:1080:flags=neighbor[front]; \
		[back][front]overlay=(W-w)/2:0,fade=in:st=0:d=0.3,fade=out:st=$FADE:d=0.4[out]" \
	-map "[out]" -map 0:a \
	-af "afade=in:st=0:d=0.3,afade=out:st=$FADE:d=0.4" \
	-c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p -r 60 -c:a aac -b:a 160k -movflags +faststart \
	"$DIR/preview_landscape.mp4"

ls -la "$DIR"/preview_*.mp4
