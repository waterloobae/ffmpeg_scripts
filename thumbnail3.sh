#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <image_file> <output_thumbnail> <text1> <text2> <text3>"
    exit 1
fi

# Assign arguments to variables
IMAGE_FILE="$1"
OUTPUT_THUMBNAIL="$2"
TEXT1="$3"
TEXT2="$4"
TEXT3="$5"

# Create temporary image files for the thumbnail in the current directory
TEMP_IMAGE_WITH_BOXES="thumbnail_boxes_temp.png"

# Draw boxes behind the text
ffmpeg -i "$IMAGE_FILE" -vf "\
drawbox=x=0:y=80:w=iw:h=200:color=black@0.3:t=fill" -y "$TEMP_IMAGE_WITH_BOXES"

# Add text to the image with boxes
ffmpeg -i "$TEMP_IMAGE_WITH_BOXES" -vf "\
drawtext=text='$TEXT1':fontcolor=white:fontsize=96:x=(w-text_w)/2:y=100:fontfile=/usr/share/fonts/truetype/msttcorefonts/Impact.ttf, \
drawtext=text='$TEXT2':fontcolor=white:fontsize=48:box=1:boxcolor=black@0.9:boxborderw=5:x=50:y=(h-text_h)-40:fontfile=/usr/share/fonts/truetype/msttcorefonts/Impact.ttf, \
drawtext=text='$TEXT3':fontcolor=yellow:fontsize=52:x=(w-text_w)/2:y=200:fontfile=/usr/share/fonts/truetype/msttcorefonts/Impact.ttf" -y "$OUTPUT_THUMBNAIL"

# Clean up the temporary image files
rm "$TEMP_IMAGE_WITH_BOXES"

# Ensure ImageMagick is installed
if ! command -v magick &> /dev/null; then
    echo "ImageMagick is not installed. Please install it using 'brew install imagemagick' on macOS."
    exit 1
fi

# Compress the thumbnail to ensure it's less than 2MB
magick "$OUTPUT_THUMBNAIL" -quality 70 -resize 1920x1080\> "$OUTPUT_THUMBNAIL"

echo "Thumbnail created and saved as $OUTPUT_THUMBNAIL"
