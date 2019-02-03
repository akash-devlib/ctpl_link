sudo rm -rf /var/tmp/ctpl_link  /opt/ctpl_link
sudo mkdir -p /var/tmp/ctpl_link
sudo mkdir -p /var/log/ctpl_link
SERVER_USERNAME=root
CLIENT_USERNAME=root
if [ `ifconfig | grep -w "inet" | awk '{print $2}' | wc -l` -eq 1 ]; then
    SERVER_IP=`ifconfig | grep -w "inet" | awk '{print $2}'`
else
    echo "Which IP to Use of Server:"
    echo  `ifconfig | grep -w "inet" | awk '{print $2}' `
    read TEMP
    SERVER_IP=`ifconfig | grep -w "inet" | awk '{print $2}' | head -$TEMP | tail -1`
fi
echo "Using $SERVER_IP as SERVER IP"
echo -n "Enter IP of Client: "
read CLIENT_IP
echo -n "Enter Root Password of Client Machine: "
read -s CLIENT_PASSWORD
echo -n "Enter Root Password of Server Machine: "
read -s SERVER_PASSWORD
cd /opt
sudo git clone https://github.com/akgjec/ctpl_link
/opt/ctpl_link/tools/set_passwordlessSSH.sh -host ${CLIENT_IP} -user ${CLIENT_USERNAME} -pass ${CLIENT_PASSWORD}
ssh $CLIENT_USERNAME@$CLIENT_IP  " mkdir -p /var/tmp/ctpl_link /var/log/ctpl_link"
ssh $CLIENT_USERNAME@$CLIENT_IP  "cd /opt; clone https://github.com/akgjec/ctpl_link"
ssh $CLIENT_USERNAME@$CLIENT_IP " /opt/ctpl_link/tools/set_passwordlessSSH.sh -host ${SERVER_IP} -user ${SERVER_USERNAME} -pass ${SERVER_PASSWORD}"

sudo /opt/ctpl_link/setup.sh $SERVER_IP $CLIENT_IP  >> /var/log/ctpl_link/install.log
ssh $CLIENT_USERNAME@$CLIENT_IP " sudo /opt/ctpl_link/setup.sh $CLIENT_IP $SERVER_IP | >> /var/log/ctpl_link/install.log "

