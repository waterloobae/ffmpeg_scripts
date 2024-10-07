#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 <video_file> <time_frame> <output_thumbnail> <text1> <text2> <text3>"
    exit 1
fi

# Assign arguments to variables
VIDEO_FILE="$1"
TIME_FRAME="$2"
OUTPUT_THUMBNAIL="$3"
TEXT1="$4"
TEXT2="$5"
TEXT3="$6"

# Create a temporary image file for the thumbnail
TEMP_IMAGE=$(mktemp /tmp/thumbnail.XXXXXX.png)
TEMP_IMAGE_WITH_BOXES=$(mktemp /tmp/thumbnail_boxes.XXXXXX.png)

# Extract the frame at the specified timeframe and scale to 1080p (use .jpg to avoid sequence confusion)
ffmpeg -ss "$TIME_FRAME" -i "$VIDEO_FILE" -vframes 1 -q:v 2 -vf "scale=1280:720" "$TEMP_IMAGE"

# Add three texts to the image using ffmpeg, with TEXT1 and TEXT2 switched
# ffmpeg -i "$TEMP_IMAGE" -vf "drawtext=text='$TEXT1':fontcolor=white:fontsize=96:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=(h-text_h)/2-260, \
# drawtext=text='$TEXT2':fontcolor=white:fontsize=42:box=1:boxcolor=black@0.9:boxborderw=5:x=(w-text_w)-170:y=(h-text_h)-30, \
# drawtext=text='$TEXT3':fontcolor=yellow:fontsize=64:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=(h-text_h)/2-160" -y "$OUTPUT_THUMBNAIL"

# ffmpeg -i "$TEMP_IMAGE" -vf "drawtext=text='$TEXT1':fontcolor=white:fontsize=96:borderw=3:bordercolor=black:x=(w-text_w)/2:y=(h-text_h)/2-260:fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf, \
# drawtext=text='$TEXT2':fontcolor=white:fontsize=42:box=1:boxcolor=black@0.9:boxborderw=5:x=(w-text_w)-170:y=(h-text_h)-30:fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf, \
# drawtext=text='$TEXT3':fontcolor=white:fontsize=64:borderw=3:bordercolor=red:x=(w-text_w)/2:y=(h-text_h)/2-160:fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" -y "$OUTPUT_THUMBNAIL"

ffmpeg -i "$TEMP_IMAGE" -vf "drawtext=text='$TEXT1':fontcolor=white:fontsize=96:borderw=3:bordercolor=black:x=(w-text_w)/2:y=(h-text_h)/2-260:fontfile=/usr/share/fonts/truetype/msttcorefonts/Impact.ttf, \
drawtext=text='$TEXT2':fontcolor=white:fontsize=42:box=1:boxcolor=black@0.9:boxborderw=5:x=(w-text_w)-170:y=(h-text_h)-30:fontfile=/usr/share/fonts/truetype/msttcorefonts/Impact.ttf, \
drawtext=text='$TEXT3':fontcolor=white:fontsize=64:borderw=3:bordercolor=red:x=(w-text_w)/2:y=(h-text_h)/2-160:fontfile=/usr/share/fonts/truetype/msttcorefonts/Impact.ttf" -y "$OUTPUT_THUMBNAIL"

# Clean up the temporary image file
rm "$TEMP_IMAGE"

# Compress the thumbnail to ensure it's less than 2MB
convert "$OUTPUT_THUMBNAIL" -quality 70 -resize 1920x1080\> "$OUTPUT_THUMBNAIL"

echo "Thumbnail created and saved as $OUTPUT_THUMBNAIL"
