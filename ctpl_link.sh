LOG_DIR=/var/log/ctpl_link
VIDEO_URL=otherserveraddress:5000/

export DISPLAY=:0
nohup python3 /opt/ctpl_link/video/main.py > ${LOG_DIR}/video.log  2>&1 &
nohup python3 /opt/ctpl_link/sound/server.py  > ${LOG_DIR}/audio_server.log  2>&1 &
nohup python3 /opt/ctpl_link/sound/client.py  > ${LOG_DIR}/audio_client.log  2>&1 &
sleep 10
nohup google-chrome ${VIDEO_URL} &

