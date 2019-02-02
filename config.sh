
SELF_IP=172.20.4.191
OPTHER_IP=172.20.4.20
sed -i 's/thisserveraddresss/$SELF_IP/g' video/main.py

sed -i 's/thisserveraddresss/$SELF_IP/g' sound/server.py

sed -i 's/otherserveraddresss/$OTHER_IP/g' sound/client.py

