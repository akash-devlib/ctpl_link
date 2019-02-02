
SELF_IP=172.20.4.191
OPTHER_IP=172.20.4.20
sed -ie "s/thisserveraddresss/$SELF_IP/ga" video/main.py

sed -ie "s/thisserveraddresss/$SELF_IP/ga" sound/server.py

sed -ie "s/otherserveraddresss/$OTHER_IP/ga" sound/client.py

