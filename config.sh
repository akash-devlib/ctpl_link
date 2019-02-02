
SELF_IP=172.20.4.191
OPTHER_IP=172.20.4.20
sed -i 's/thisserveraddresss/$SELF_IP/ga' ./video/main.py

sed -i 's/thisserveraddresss/$SELF_IP/ga' ./sound/server.py

sed -i 's/otherserveraddresss/$OTHER_IP/ga' ./sound/client.py

