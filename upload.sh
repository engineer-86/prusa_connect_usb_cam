#!/bin/bash

# Set default values for environment variables
: "${HTTP_URL:=https://webcam.connect.prusa3d.com/c/snapshot}"
: "${DELAY_SECONDS:=10}"
: "${LONG_DELAY_SECONDS:=60}"
: "${VIDEO_DEVICE:=/dev/video0}"

while true; do
    # Grab a frame from the webcam using FFmpeg
    ffmpeg \
        -loglevel quiet \
        -stats \
        -y \
        -f v4l2 \
        -framerate 1 \
        -video_size 1280x720 \
        -i "$VIDEO_DEVICE" \
        -vframes 1 \
        -pix_fmt yuvj420p \
        output.jpg

    # If no error, upload it.
    if [ $? -eq 0 ]; then
        # POST the image to the HTTP URL using curl
        curl -X PUT "$HTTP_URL" \
            -H "accept: */*" \
            -H "content-type: image/jpg" \
            -H "fingerprint: $FINGERPRINT" \
            -H "token: $TOKEN" \
            --data-binary "@output.jpg" \
            --no-progress-meter \
            --compressed

        # Reset delay to the normal value
        DELAY=$DELAY_SECONDS
    else
        echo "FFmpeg returned an error. Retrying after ${LONG_DELAY_SECONDS}s..."
        
        # Set delay to the longer value
        DELAY=$LONG_DELAY_SECONDS
    fi

    sleep "$DELAY"
done
