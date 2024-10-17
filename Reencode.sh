#!/bin/bash

# Check if input and output arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_file> <output_file>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

# Display encoding options
echo "Select a re-encoding option:"
echo "1. Standard re-encode (H.264, CRF 23)"
echo "2. Fix timecode issues"
echo "3. Convert variable frame rate (VFR) to constant frame rate (CFR)"

# Read user input
read -p "Enter your choice (1/2/3): " choice

# Re-encode based on the selected option
case "$choice" in
    1)
        echo "Re-encoding with standard settings..."
        ffmpeg -hwaccel auto -i "$INPUT_FILE" -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k "$OUTPUT_FILE"
        ;;
    2)
        echo "Fixing timecode issues..."
        ffmpeg -hwaccel auto -i "$INPUT_FILE" -vf setpts=PTS-STARTPTS -c:v libx264 -crf 23 -c:a copy "$OUTPUT_FILE"
        ;;
    3)
        echo "Converting variable frame rate (VFR) to constant frame rate (CFR)..."
        ffmpeg -hwaccel auto -i "$INPUT_FILE" -r 30 -c:v libx264 -crf 23 -c:a copy "$OUTPUT_FILE"
        ;;
    *)
        echo "Invalid option. Please choose 1, 2, or 3."
        exit 1
        ;;
esac

echo "Re-encoding completed!"