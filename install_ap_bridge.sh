#! /bin/bash
# Configure automatically a bridged wireless access point for raspberrypi
# All the configuration is from https://www.raspberrypi.com/documentation/computers/configuration.html#setting-up-a-bridged-wireless-access-point
# I adapt it to simplify and do it quickly
# Enter in command prompt:
# $ sudo ./install_ap_bridge.sh SSID PSW
# Where SSID is your ssid and PSW is your password
#
#                                         +- RPi -------+
#                                     +---+ 10.10.0.2   |          +- Laptop ----+
#                                     |   |     WLAN AP +-)))  (((-+ WLAN Client |
#                                     |   |  Bridge     |          | 10.10.0.5   |
#                                     |   +-------------+          +-------------+
#                 +- Router ----+     |
#                 | Firewall    |     |   +- PC#2 ------+
#(Internet)---WAN-+ DHCP server +-LAN-+---+ 10.10.0.3   |
#                 |   10.10.0.1 |     |   +-------------+
#                 +-------------+     |
#                                     |   +- PC#1 ------+
#                                     +---+ 10.10.0.4   |
#                                         +-------------+

echo "Configuring a host access point"
echo "SSID:$1"
echo "PSK:$2"

# In order to work as a bridged access point, the Raspberry Pi
# needs to have the hostapd access point software package installed:
apt install hostapd
# Enable the wireless access point service and set it to start
# when your Raspberry Pi boots:
systemctl unmask hostapd
systemctl enable hostapd

# Add a bridge network device named br0 by creating a file:
echo "[NetDev]" > /etc/systemd/network/bridge-br0.netdev
echo "Name=br0" >> /etc/systemd/network/bridge-br0.netdev
echo "Kind=bridge" >> /etc/systemd/network/bridge-br0.netdev

# Add a bridge network device named br0 by creating a file:
echo "[Match]" > /etc/systemd/network/br0-member-eth0.network
echo "Name=eth0" >> /etc/systemd/network/br0-member-eth0.network
echo "" >> /etc/systemd/network/br0-member-eth0.network
echo "[Network]" >> /etc/systemd/network/br0-member-eth0.network
echo "Bridge=br0" >> /etc/systemd/network/br0-member-eth0.network


# Now enable the systemd-networkd service to create and populate
# the bridge when your Raspberry Pi boots:
systemctl enable systemd-networkd

mv /etc/dhcpcd.conf /etc/dhcpcd.conf.orig
while read line; do
	if [[ "$line" == *"interface"* ]]; then
		echo "" >> /etc/dhcpcd.conf
		echo "denyinterfaces wlan0 eth0" >> /etc/dhcpcd.conf
		echo "" >> /etc/dhcpcd.conf
	fi
	echo $line >> /etc/dhcpcd.conf
done < /etc/dhcpcd.conf.orig
echo $line >> /etc/dhcpcd.conf
echo "" >> /etc/dhcpcd.conf
echo "interface br0" >> /etc/dhcpcd.conf


# To ensure WiFi radio is not blocked on your Raspberry Pi,
rfkill unblock wlan

# Create the hostapd configuration file, located at /etc/hostapd/hostapd.conf,
# to add the various parameters for your new wireless network.
echo "country_code=FR" > /etc/hostapd/hostapd.conf
echo "interface=wlan0" >> /etc/hostapd/hostapd.conf
echo "bridge=br0" >> /etc/hostapd/hostapd.conf
echo "ssid=$1" >> /etc/hostapd/hostapd.conf
echo "hw_mode=g" >> /etc/hostapd/hostapd.conf
echo "channel=7" >> /etc/hostapd/hostapd.conf
echo "macaddr_acl=0" >> /etc/hostapd/hostapd.conf
echo "auth_algs=1" >> /etc/hostapd/hostapd.conf
echo "ignore_broadcast_ssid=0" >> /etc/hostapd/hostapd.conf
echo "wpa=2" >> /etc/hostapd/hostapd.conf
echo "wpa_passphrase=$2" >> /etc/hostapd/hostapd.conf
echo "wpa_key_mgmt=WPA-PSK" >> /etc/hostapd/hostapd.conf
echo "wpa_pairwise=TKIP" >> /etc/hostapd/hostapd.conf
echo "rsn_pairwise=CCMP" >> /etc/hostapd/hostapd.conf

echo "Finish configuring the host access point"
echo "Reboot in 5s"
sleep 5
systemctl reboot