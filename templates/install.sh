VERSION=2013.4.0

#apt-get install build-essential
su -c "apt-get install linux-headers-$(uname -r)"
#apt-get install pkg-config
#apt-get install libnl-3-dev

git clone https://github.com/freifunk-gluon/batman-adv-legacy.git
cd batman-adv-legacy
make
su -c "make install"
cd ..
rm -rf batman-adv-legacy

# batman-adv for versions > 2014.3.0
#wget http://downloads.open-mesh.org/batman/releases/batman-adv-$VERSION/batman-adv-$VERSION.tar.gz
#tar -xzf batman-adv-$VERSION.tar.gz
#cd batman-adv-$VERSION/
#make
#make install
#cd ..
#rm -rf batman-adv-$VERSION*

wget http://downloads.open-mesh.org/batman/releases/batman-adv-$VERSION/batctl-$VERSION.tar.gz
tar -xzf batctl-$VERSION.tar.gz
cd batctl-$VERSION/
make
su -c "make install"
cd ..
rm -rf batctl-$VERSION*

VERSION=2014.4.0

wget http://downloads.open-mesh.org/batman/stable/sources/alfred/alfred-$VERSION.tar.gz
tar -xzf alfred-$VERSION.tar.gz
cd alfred-$VERSION/
make CONFIG_ALFRED_GPSD=n
su -c "make CONFIG_ALFRED_GPSD=n install"
cd ..
rm -rf alfred-$VERSION*


echo 'conf-dir=/etc/dnsmasq.d,.bak' >> /etc/dnsmasq.conf

vnstat --create -i ffks-mesh
vnstat --create -i ffks-client
vnstat --create -i ffks-br
vnstat --create -i bat0
vnstat --create -i tun0
