
#SELF_IP=
#OPTHER_IP=
sed -i 's/thisserveraddresss/$SELF_IP/g' video/main.py

sed -i 's/thisserveraddresss/$SELF_IP/g' audio/server.py

sed -i 's/otherserveraddresss/$OTHER_IP/g' audio/client.py

