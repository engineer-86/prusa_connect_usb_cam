# Prusa Camera Docker Setup

This project sets up a Docker container to capture images from a Logitech C270 (or any other) webcam and upload them to a specified URL. The configuration is managed via a `.env` file for easy customization.

## Prerequisites

- Docker
- Docker Compose
- TOKEN and FIGERPRINT from Prusa Connect
   - please check the guide from [nunofgs](https://gist.github.com/nunofgs/84861ee453254823be6b069ebbce9ad2)

## Setup Instructions

1. **Clone the repository:**

   ```bash
   git clone https://github.com/engineer-86/prusa_connect_usb_cam

   cd prusa_connect_usb_cam
   ```

2. **Create and configure the `.env` file:**

   Rename the `.env.template` to `.env` in the project directory with the following content:

   ```dotenv
        HTTP_URL=https://webcam.connect.prusa3d.com/c/snapshot
        DELAY_SECONDS=10
        LONG_DELAY_SECONDS=60
        VIDEO_DEVICE=<your_video_device> # e.g. /dev/video0
        FINGERPRINT=<your_fingerprint>
        TOKEN=<your_token>
   ```

3. **Update the `docker-compose.yml` file:**

   Ensure your `docker-compose.yml` file is as follows:

   ```yaml
   version: '3.8'

   services:
     prusa-camera:
       image: linuxserver/ffmpeg
       restart: always
       entrypoint: /bin/bash
       command: /upload.sh
       env_file:
         - .env
       devices:
         - /dev/video0:/dev/video0
       volumes:
         - ./upload.sh:/upload.sh
   ```

4. **Create the `upload.sh` script:**

   Create an `upload.sh` file in the project directory with the following content:

   ```bash
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
   ```

   Make sure the script is executable:

   ```bash
   chmod +x upload.sh
   ```

5. **Start the Docker container:**

   Run the following command to start the Docker container:

   ```bash
   docker-compose up -d
   ```

6. **Check the logs:**

   Verify that the service is running correctly by checking the logs:

   ```bash
   docker-compose logs -f prusa-camera
   ```

## Environment Variables

- `HTTP_URL`: The URL where the images will be uploaded.
- `DELAY_SECONDS`: The delay between each image capture in seconds.
- `LONG_DELAY_SECONDS`: The delay after an error occurs before retrying in seconds.
- `VIDEO_DEVICE`: The video device used for capturing images (e.g., `/dev/video0`).
- `FINGERPRINT`: The fingerprint used for the HTTP request header.
- `TOKEN`: The token used for the HTTP request header.

## Acknowledgements

This project was inspired by [nunofgs](https://gist.github.com/nunofgs/84861ee453254823be6b069ebbce9ad2).
He created the script to capture images from a webcam and upload them to a specified URL. Thanks to him for the inspiration.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
