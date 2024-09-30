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
STABILIZED_OUTPUT="${FINAL_OUTPUT%.*}_final.mp4"
TRANSFORM_FILE="${FINAL_OUTPUT%.*}_transform.trf"

# Email details
email_subject="Video Processing Completed"
email_body="The video processing job has been completed."
recipient_email="terry.bae@gmail.com"  # Replace with your email address

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

# Step 1: Generate the stabilization transform file
# echo "Generating stabilization transform file..."
# 
# ffmpeg  -hwaccel auto -i "$FINAL_OUTPUT" -vf vidstabdetect=shakiness=5:accuracy=15:result="$TRANSFORM_FILE" -f null -
#  if [[ $? -ne 0 ]]; then
#    echo "Error: Failed to generate stabilization transform file."
#    deactivate
#    exit 1
# fi

# Step 2: Apply the stabilization transform to the video
# echo "Applying stabilization to the final output video..."
# ffmpeg -hwaccel auto -i "$FINAL_OUTPUT" -vf vidstabtransform=input="$TRANSFORM_FILE",unsharp=5:5:0.8:3:3:0.4 -vcodec h264_videotoolbox -b:v 5000k -acodec copy "$STABILIZED_OUTPUT"
# if [[ $? -ne 0 ]] || [ ! -s "$STABILIZED_OUTPUT" ]]; then
#    echo "Error: Failed to stabilize the video or stabilized video is empty."
#    deactivate
#    exit 1
# fi

Clean up intermediate files
echo "Cleaning up intermediate files..."
rm "$EXTRACTED_AUDIO" "$TRANSFORM_FILE"

# Deactivate the virtual environment
deactivate

# Send an email notification
# echo -e "$email_body" | mail -s "$email_subject" "$recipient_email"

# echo "Process completed successfully. Stabilized output: $STABILIZED_OUTPUT"
