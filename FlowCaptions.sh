#!/bin/bash

# Check if input video and captions text file are provided
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 input_video output_video captions_file"
  exit 1
fi

# Input video, output video, and captions file
INPUT_VIDEO="$1"
OUTPUT_VIDEO="$2"
CAPTIONS_FILE="$3"

# Read the captions from the file
CAPTIONS=$(cat "$CAPTIONS_FILE")

# Get video dimensions
VIDEO_WIDTH=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$INPUT_VIDEO")

# Get video duration in seconds
DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$INPUT_VIDEO")

# Set up parameters
SCROLL_SPEED=50  # Adjust to make scrolling speed slower or faster
FONT_SIZE=76     # Customize font size
FONT_COLOR="white"
BACKGROUND_COLOR="red@0.5"  # Red background with 50% opacity
POSITION_Y="(h-100)"  # Position the text 100px above the bottom of the video
BOX_BORDER_WIDTH=10  # Padding around the text (in pixels)

# Calculate the time it takes for the text to scroll fully across the screen based on the video width
# Speed factor affects how fast the text moves across
TEXT_SCROLL_TIME=$(echo "($VIDEO_WIDTH / $SCROLL_SPEED)" | bc)

FFMPEG_FILTER="drawtext=text='$CAPTIONS':fontcolor=$FONT_COLOR:fontsize=$FONT_SIZE:x=w-mod(t*$SCROLL_SPEED\,w+tw):y=$POSITION_Y:box=1:boxcolor=$BACKGROUND_COLOR:boxborderw=$BOX_BORDER_WIDTH:enable='between(t,0,$DURATION)'"

# Run ffmpeg command to embed scrolling captions with proper repeat timing and background
ffmpeg -i "$INPUT_VIDEO" -vf "$FFMPEG_FILTER" -codec:a copy "$OUTPUT_VIDEO"