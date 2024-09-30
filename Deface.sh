#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_video_file>"
    exit 1
fi

# Assign argument to variable
INPUT_VIDEO=$1
EXTRACTED_AUDIO="${INPUT_VIDEO%.*}_extracted_audio.mp3"
ANONYMIZED_VIDEO="${INPUT_VIDEO%.*}_anonymized.mp4"
FINAL_OUTPUT="${INPUT_VIDEO%.*}_blurred.mp4"
FINAL_OUTPUT2="${INPUT_VIDEO%.*}_final.mp4"

# Activate the virtual environment
source ~/venv/bin/activate

# Extract audio from the original video
echo "Extracting audio from the original video..."
ffmpeg  -hwaccel auto -i "$INPUT_VIDEO" -q:a 0 -map a "$EXTRACTED_AUDIO"
if [[ $? -ne 0 ]] || [ ! -s "$EXTRACTED_AUDIO" ]]; then
    echo "Error: Failed to extract audio from the video or audio is empty."
    deactivate
    exit 1
fi

# Blur faces on the input video using deface
echo "Blurring faces on the input video..."
deface --scale 2560x1440 --thresh 0.5 "$INPUT_VIDEO"
if [[ $? -ne 0 ]] || [ ! -s "$ANONYMIZED_VIDEO" ]]; then
    echo "Error: Failed to blur faces on the input video or anonymized video is empty."
    deactivate
    exit 1
fi

# Add the extracted audio back to the anonymized video
echo "Adding extracted audio back to the anonymized video..."
ffmpeg -hwaccel auto -i "$ANONYMIZED_VIDEO" -i "$EXTRACTED_AUDIO" -c copy -map 0:v:0 -map 1:a:0 "$FINAL_OUTPUT"
if [[ $? -ne 0 ]] || [ ! -s "$FINAL_OUTPUT" ]]; then
    echo "Error: Failed to add audio to the anonymized video or final video is empty."
    deactivate
    exit 1
fi

Clean up intermediate files
echo "Cleaning up intermediate files..."
rm "$EXTRACTED_AUDIO" "$ANONYMIZED_VIDEO"

# Deactivate the virtual environment
deactivate

# Cut the first 2 seconds and apply fade-in effect
ffmpeg -hwaccel auto -i "$FINAL_OUTPUT" -vf "fade=in:0:60" -c:a copy "part1.mp4"

# Cut the last 2 seconds and apply fade-out effect
DURATION=$(ffmpeg -i "$FINAL_OUTPUT" 2>&1 | grep "Duration" | cut -d ' ' -f 4 | sed s/,//)
ffmpeg -hwaccel auto -i "$FINAL_OUTPUT" -vf "fade=out:st=$(echo "$DURATION - 2" | bc):d=2" -c:a copy "part3.mp4"

# Extract the middle part of the video
ffmpeg -hwaccel auto -i "$FINAL_OUTPUT" -ss 00:00:02 -to $(echo "$DURATION - 2" | bc) -c copy "part2.mp4"

# Concatenate the three parts
ffmpeg -f concat -safe 0 -i <(for f in part1.mp4 part2.mp4 part3.mp4; do echo "file '$PWD/$f'"; done) -c copy "$FINAL_OUTPUT2"

# Clean up intermediate files
rm part1.mp4 part2.mp4 part3.mp4

# Send an email notification
# echo -e "$email_body" | mail -s "$email_subject" "$recipient_email"

# echo "Process completed successfully. Stabilized output: $STABILIZED_OUTPUT"
