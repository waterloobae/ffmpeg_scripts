#!/bin/bash

# Check if both input and output files are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <input_audio_file> <output_audio_file>"
    exit 1
fi

# Input and output audio files
INPUT_FILE="$1"
OUTPUT_FILE="$2"

# Add 2 seconds of silence at the beginning
ffmpeg -i "$INPUT_FILE" -filter_complex "aevalsrc=0:d=2 [silence]; [silence][0:a] concat=n=2:v=0:a=1" "$OUTPUT_FILE"
