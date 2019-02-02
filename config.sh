
#SELF_IP=172.20.4.20
#OTHER_IP=172.20.4.191
sed -ie "s/thisserveraddress/$SELF_IP/g" video/main.py

sed -ie "s/thisserveraddress/$SELF_IP/g" sound/server.py

sed -ie "s/otherserveraddress/$OTHER_IP/g" sound/client.py

