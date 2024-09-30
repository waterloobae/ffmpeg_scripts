#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <start_time> <end_time> <input_video> <output_video>"
    exit 1
fi

# Assign arguments to variables
START_TIME=$1
END_TIME=$2
INPUT_VIDEO=$3
OUTPUT_VIDEO=$4

# Debugging information
echo "Trimming video from $START_TIME to $END_TIME"
echo "Input file: $INPUT_VIDEO"
echo "Output file: $OUTPUT_VIDEO"

# Step 1: Trim the video between the start and end time
ffmpeg -hwaccel auto -ss "$START_TIME" -to "$END_TIME" -i "$INPUT_VIDEO" -c copy trimmed_video.mp4

# Check if trimming was successful
if [ $? -ne 0 ]; then
    echo "An error occurred during video trimming."
    exit 1
fi

# Step 2: Resize and crop the video for YouTube Shorts (9:16 aspect ratio)
echo "Resizing and cropping the video for YouTube Shorts (1080x1920)"
ffmpeg -hwaccel auto -i trimmed_video.mp4 -vf "crop=ih*(9/16):ih,scale=1080:1920" -c:a copy "$OUTPUT_VIDEO"

# Check if resizing and cropping were successful
if [ $? -eq 0 ]; then
    echo "Video trimmed and resized for YouTube Shorts successfully!"
    # Clean up the intermediate trimmed video
    rm trimmed_video.mp4
else
    echo "An error occurred during resizing and cropping."
fi
