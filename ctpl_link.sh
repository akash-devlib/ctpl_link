LOG_DIR=/var/log/ctpl_link
VIDEO_URL=$1
nohup python3 video/main.py > ${LOG_DIR}/video.log  2>&1 &
nohup python3 sound/server.py  > ${LOG_DIR}/audio_server.log  2>&1 &
nohup python3 sound/client.py  > ${LOG_DIR}/audio_client.log  2>&1 &

firefox -new-window ${VIDEO_URL}

