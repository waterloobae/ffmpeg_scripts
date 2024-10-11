#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <image1> <image2>"
  exit 1
fi

image1=$1
image2=$2
output_video="output.mp4"
temp_dir=$(mktemp -d)
# Resize images to 4k with padding using magick
magick "$image1" -resize 3840x2160\> -background black -gravity center -extent 3840x2160 "$temp_dir/resized1.png"
magick "$image2" -resize 3840x2160\> -background black -gravity center -extent 3840x2160 "$temp_dir/resized2.png"

# Create a video from the images
ffmpeg -y -framerate 1/5 -i "$temp_dir/resized%d.png" -c:v libx264 -r 30 -pix_fmt yuv420p -vf "scale=3840:2160" "$output_video"

# Clean up
rm -rf "$temp_dir"

echo "Video created: $output_video"