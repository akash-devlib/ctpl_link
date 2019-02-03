sudo mkdir -p /var/tmp/ctpl_link
sudo mkdir -p /var/log/ctpl_link
sudo mkdir -p /opt/ctpl_link
SELF_IP=$1
OTHER_IP=$2
if ! sudo apt-get -y update; then
    RET=1; exit $RET
fi
if ! sudo apt-get -y upgrade; then
    RET=1; exit $RET
fi
if ! sudo apt-get -y install build-essential cmake unzip pkg-config libjpeg-dev \
    libpng-dev libtiff-dev libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
    libxvidcore-dev libx264-dev libgtk-3-dev libatlas-base-dev expect sshpass \
    gfortran python3-dev firefox gnome-session gdm3 gnome-terminal; then
    RET=1; exit $RET
fi
sudo systemctl set-default graphical.target
cd /var/tmp/ctpl_link
if ! wget https://bootstrap.pypa.io/get-pip.py; then
    RET=1; exit $RET
fi
if ! sudo python3 get-pip.py; then
    RET=1; exit $RET
fi
if ! sudo pip3 install numpy flask; then
    RET=1; exit $RET
fi
if ! pip3 install opencv-python==3.4.4.19; then
    RET=1; exit $RET
fi
cd /opt/ctpl_link
sed -ie "s/thisserveraddress/$SELF_IP/g" /opt/ctpl_link/video/main.py
sed -ie "s/thisserveraddress/$SELF_IP/g" /opt/ctpl_link/sound/server.py
sed -ie "s/otherserveraddress/$OTHER_IP/g" /opt/ctpl_link/sound/client.py
sed -ie "s/otherserveraddress/$OTHER_IP/g" /opt/ctpl_link/ctpl_link.sh

if ! [ "$(getent passwd vlink)"  ]; then
   useradd -d /home/vlink vlink
   mkdir -p  /home/vlink
   chown -R vlink:vlink /home/vlink
   echo "vlink:ssl12345" > /var/tmp/pass.txt
   cat /var/tmp/pass.txt | chpasswd
fi
chmod -R 777  /var/log/ctpl_link
chmod -R 755  /opt/ctpl_link

#Configure autologin in gdm
cp /opt/ctpl_link/custom.conf /etc/gdm3/custom.conf

systemctl stop gdm3
PID=$(ps -aef | grep vlink | grep gdm | grep -v grep | awk '{print $2}' | xargs)
if [ x != x$PID ]; then
    kill -9 $PID
fi
systemctl start gdm3
sleep 60

VIDEO_URL=${OTHER_IP}:5000
su vlink -c "/opt/ctpl_link/ctpl_link.sh ${VIDEO_URL}"

