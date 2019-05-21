#!/bin/sh
# Routing tables name
host_rt=host
vpn_rt=vpnconn
# Devices for host and VPN
host_dev=eth0
vpn_dev=ppp0
# Basic commands
cmdip=/sbin/ip
deleter1=$cmdip" rule del"
deleterd=$cmdip" route del default dev"
subnet1_net=192.168.1.0/24
subnet2_net=192.168.4.0/24
single_user=172.16.1.6

# Get data
host_ip=$(/sbin/ifconfig $host_dev | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')
vpn_ip=$(/sbin/ifconfig $vpn_dev | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')
vpn_gw=$(/sbin/ifconfig $vpn_dev | grep 'P-t-P' | cut -d: -f3 | awk '{print $1}')
host_gw=$(ip route | grep 'default via' | grep 'dev '$host_dev | awk '{print $3}')

echo "This host ip is: "$host_ip "and gateway: "$host_gw
echo "VPN tunnel up with: "$vpn_ip "and gateway: "$vpn_gw
echo "Subnet1 Network:" $subnet1_net "Kiev Network:" $subnet2_net
echo "Delete old rules"
# Delete previously old Routing tables and marks
$deleter1 fwmark 0x1/0x3 lookup 201
$deleter1 from $host_ip lookup 201
$deleter1 fwmark 0x2/0x3 lookup 202
$deleter1 from $vpn_ip lookup 202
$deleter1 from $subnet1_net lookup 202
$deleter1 from $subnet2_net lookup 202
#
$deleterd $vpn_dev table 202
$deleterd $host_dev table 201
$deleterd $vpn_dev metric 2000
$deleterd $host_dev metric 1000
# Add new one
echo "Add new one:"
$cmdip rule add fwmark 0x1/0x3 lookup 201
$cmdip rule add from $host_ip lookup 201
$cmdip rule add fwmark 0x2/0x3 lookup 202
$cmdip rule add from $vpn_ip lookup 202
$cmdip rule add from $subnet1_net lookup 202
$cmdip rule add from $subnet2_net lookup 202
#
$cmdip route add default dev $vpn_dev table 202
$cmdip route add default dev $host_dev table 201
$cmdip route add default dev $vpn_dev metric 2000
$cmdip route add default dev $host_dev metric 1000
#
# IPTABLES
# Get IP from temp
old_vpn_ip=$(cat /tmp/vpnip)

# Check iptables
ck_iptables=$(iptables --table nat --list | grep to:$old_vpn_ip | wc -l)

if [ $ck_iptables -gt 2 ]
then
        echo `date` " : DELETE RULE"
        iptables -t nat -D POSTROUTING -s $single_user -o $vpn_dev -j SNAT --to-source $old_vpn_ip
        iptables -t nat -D POSTROUTING -s 192.168.1.0/24 -o $vpn_dev -j SNAT --to-source $old_vpn_ip
        iptables -t nat -D POSTROUTING -s 192.168.4.0/24 -o $vpn_dev -j SNAT --to-source $old_vpn_ip
        echo > /tmp/vpnip
        echo $vpn_ip > /tmp/vpnip
        iptables -t nat -I POSTROUTING -s $single_user -o $vpn_dev -j SNAT --to-source $vpn_ip
        iptables -t nat -I POSTROUTING -s 192.168.1.0/24 -o $vpn_dev -j SNAT --to-source $vpn_ip
        iptables -t nat -I POSTROUTING -s 192.168.4.0/24 -o $vpn_dev -j SNAT --to-source $vpn_ip
else
        echo `date` " : NOT NEED DELETE"
        echo > /tmp/vpnip
        echo $vpn_ip > /tmp/vpnip
fi