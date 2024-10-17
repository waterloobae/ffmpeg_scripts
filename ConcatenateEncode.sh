#!/bin/bash

# Usage: ./concat_encode.sh filelist.txt output_file

# Check if two arguments are passed (filelist and output file)
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 filelist.txt output_file"
    exit 1
fi

FILELIST=$1
OUTPUT_FILE=$2

# Check if the filelist exists and is not empty
if [ ! -s "$FILELIST" ]; then
    echo "Filelist $FILELIST is empty or does not exist."
    exit 1
fi

# Run ffmpeg to concatenate and re-encode the video files with hardware acceleration
ffmpeg -hwaccel videotoolbox -f concat -safe 0 -i "$FILELIST" -c:v h264_videotoolbox -b:v 50M -c:a aac -b:a 192k "$OUTPUT_FILE"

echo "Concatenation and encoding complete. Output saved to $OUTPUT_FILE."