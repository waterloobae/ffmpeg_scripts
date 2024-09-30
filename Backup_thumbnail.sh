#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <video_file> <time_frame> <output_thumbnail> <text1> <text2>"
    exit 1
fi

# Assign arguments to variables
VIDEO_FILE="$1"
TIME_FRAME="$2"
OUTPUT_THUMBNAIL="$3"
TEXT1="$4"
TEXT2="$5"

# Create a temporary image file for the thumbnail
TEMP_IMAGE=$(mktemp /tmp/thumbnail.XXXXXX.png)

# Extract the frame at the specified timeframe and scale to 1080p
ffmpeg -ss "$TIME_FRAME" -i "$VIDEO_FILE" -vframes 1 -q:v 2 -vf "scale=1280:720" "$TEMP_IMAGE"

# Add two texts to the image using ffmpeg
ffmpeg -i "$TEMP_IMAGE" -vf "drawtext=text='$TEXT1':fontcolor=yellow:fontsize=62:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=(h-text_h)/2+140, drawtext=text='$TEXT2':fontcolor=white:fontsize=96:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=(h-text_h)/2+220" -y "$OUTPUT_THUMBNAIL"

# Clean up the temporary image file
rm "$TEMP_IMAGE"

# Compress the thumbnail to ensure it's less than 2MB
convert "$OUTPUT_THUMBNAIL" -quality 85 -resize 1920x1080\> "$OUTPUT_THUMBNAIL"

echo "Thumbnail created and saved as $OUTPUT_THUMBNAIL"

