#!/bin/bash

function set_if_conf {
    echo
    echo -n "Should we use DHCP for that interface (Y/n)?";read -n 1 dhcpsw
    if [[ $dhcpsw == "n" || $dhcpsw == "N" ]]; then
        echo
        echo -n "Enter ip: "; read ${intf}_ip;
        echo -n "Enter netmask: "; read ${intf}_mask
        echo -n "Enter default gw: "; read ${intf}_gw
        echo -n "Enter First DNS server: "; read ${intf}_dns1
        echo -n "Enter Second DNS server: "; read ${intf}_dns2
    else
        eval ${intf}_ip="";eval ${intf}_mask="";eval ${intf}_gw="";eval ${intf}_dns1="";eval ${intf}_dns2=""
    fi
    echo
}

function save_if_cfg {
    scrFile="/etc/sysconfig/network-scripts/ifcfg-$device"
    hwaddr=`ifconfig $device | grep -i hwaddr | sed -e 's#^.*hwaddr[[:space:]]*##I'`
    [ -z $gw ] || echo GATEWAY=$gw >> /etc/sysconfig/network
    echo DEVICE=$device > $scrFile
    echo ONBOOT=yes >> $scrFile
    echo NM_CONTROLLED=no >> $scrFile
    echo HWADDR=$hwaddr >> $scrFile
    echo USERCTL=no >> $scrFile
    if [ $ip ]; then
        echo BOOTPROTO=static >> $scrFile
        echo IPADDR=$ip >> $scrFile
        echo NETMASK=$netmask >> $scrFile
        [ $dns1 ] && echo DNS1=$dns1 >> $scrFile
        [ $dns2 ] && echo DNS2=$dns2 >> $scrFile
    else
        echo BOOTPROTO=dhcp >> $scrFile
    fi
}

function default_settings {
    hostname="fuel-pm"
    domain="local"
    mgmt_if="eth0"
    mgmt_ip="10.0.0.100"
    mgmt_mask="255.255.0.0"
    ext_if="eth1"
    dhcp_start_address="10.0.0.201"
    dhcp_end_address="10.0.0.254"
    mirror_type="default"
}

function apply_settings {
    echo;echo "Applying settings ..."

# Network interfaces settings apply
    for iftype in ext mgmt
    do
        eval device=\$${iftype}_if
        eval ip=\$${iftype}_ip
        eval netmask=\$${iftype}_mask
        eval gw=\$${iftype}_gw
        eval dns1=\$${iftype}_dns1
        eval dns2=\$${iftype}_dns2
        hwaddr=`ifconfig $device | grep -i hwaddr | sed -e 's#^.*hwaddr[[:space:]]*##I'`
        save_if_cfg
    done

# Cobbler settings apply
    : ${server:=$mgmt_ip}
    : ${domain_name=$domain}
    : ${name_server=$mgmt_ip}
    : ${next_server=$mgmt_ip}
    : ${dhcp_netmask=$mgmt_mask}
    : ${dhcp_gateway=$mgmt_ip}
    : ${cobbler_user="cobbler"}
    : ${cobbler_password="cobbler"}
    : ${pxetimeout="0"}
    : ${dhcp_interface=$mgmt_if}

# Domain/Hostname apply
    sed -i -e 's#^\(HOSTNAME=\).*$#\1'"$hostname.$domain"'#' /etc/sysconfig/network
    rm -f /var/lib/puppet/ssl/ca/signed/*
    [ -n "$mgmt_ip" -a -n "$ext_ip" ] && sed -i '/nameserver/d' /etc/resolv.conf && echo "nameserver 127.0.0.1;" >> /etc/resolv.conf
    [ -z "$mgmt_ip" ] && echo "prepend domain-name-servers 127.0.0.1;" >> /etc/dhclient-$mgmt_if.conf
    [ -z "$ext_ip" ] && echo "prepend domain-name-servers 127.0.0.1;" >> /etc/dhclient-$ext_if.conf
    [ -z "$mgmt_ip" ] || grep -Eq "^\s*$mgmt_ip\s+$hostname" /etc/hosts || \ 
    sed -i "/$mgmt_ip/d" /etc/hosts && echo "$mgmt_ip    $hostname.$domain $hostname" >> /etc/hosts
    sed -i '/kernel.hostname/d' /etc/sysctl.conf && echo "kernel.hostname=$hostname" >> /etc/sysctl.conf
    sed -i '/kernel.domainname/d' /etc/sysctl.conf && echo "kernel.domainname=$domain" >> /etc/sysctl.conf
    sed -i '/server/d' /etc/puppet/puppetdb.conf && echo "server = $hostname.$domain" >> /etc/puppet/puppetdb.conf
    service network restart
    service puppetdb restart
    sed -i "s%\(^.*address is:\).*$%\1 `ip address show $ext_if | awk '/inet / {print \$2}' | cut -d/ -f1 -`%" /etc/issue
}


function show_top {
clear
echo "Domain: $domain"
echo "Hostname: $hostname"
echo "PXE range: $dhcp_start_address - $dhcp_end_address"
echo "Mirror set to use: $mirror_type"
echo -n "Parent proxy: "
if [ -z "$parent_proxy" ];then echo "none (direct access)"
else
echo $parent_proxy
fi
column -t -s% <(
echo "Management interface: $mgmt_if%External interface: $ext_if"
echo "IP address: ${mgmt_ip:="DHCP"}%IP address: ${ext_ip:="DHCP"}"
echo "Netmask: $mgmt_mask%Netmask: $ext_mask"
echo "Gateway: $mgmt_gw%Gateway:$ext_gw"
echo "DNS Server 1: $mgmt_dns1%DNS Server 1: $ext_dns1"
echo "DNS Server 2: $mgmt_dns2%DNS Server 2: $ext_dns2"
echo
)
echo
}

function show_msg {
echo "Menu:"
echo "1. Change FQDN for masternode and cloud domain"
echo "2. Configure openstack cloud management interface"
echo "3. Configure external interface with repositories/internet access"
echo "4. Change IP range to use for baremetal provisioning via PXE"
echo "5. Choose set of mirror to use (default/custom)"
echo "6. Configure to use parent proxy"
echo "9. Quit"
echo -n "Please, select an action to do:"
}

function menu_conf {
while [ $endconf -ne 1 ]; do
    show_top
    show_msg
    read -n 1 -t 5 answer
    if [ $? -gt 128 -a -f /root/fuel.defaults ]; then
        source /root/fuel.defaults
        endconf=1
    else
    case $answer in
        1)
            show_top
            echo "WARNING. Changing master hostname or domain name will make you existing puppet"
            echo "keys and configuration files invalid!!!"
            echo "If you already have deployed any nodes using current hostname or domain name,"
            echo "you have either to re-deploy existing nodes including operating system"
            echo "installation or manually remove puppet cache and keys on every deployed node"
            echo "with 'rm -rf /var/lib/puppet' and manually change all affected puppet and"
            echo "mcollective configuration files!"
            echo "If there is no deployed nodes in your current installation - then it is safe"
            echo "to change hostname and domain name."
            echo "This script will remove current puppet master key automatically."
            echo
            echo -n "Please enter hostname for this puppetmaster/cobbler: "; read hostname
            echo -n "Please enter domain name for this cloud: "; read domain
            ;;
        2)
            show_top
            echo -n "Please specify interface to use for management network: "; read mgmt_if
            intf="mgmt"
            set_if_conf
            ;;
        3)
            show_top
            echo -n "Please specify interface to access repositories/internet: "; read ext_if
            intf="ext"
            set_if_conf
            ;;
        4)
            show_top
            echo -n "Please enter start address: "; read dhcp_start_address
            echo -n "Please enter end address: "; read dhcp_end_address
            ;;
        5)
            show_top
            echo -n "Please select set of mirrors to use(default/custom): "; read mirror_type
            ;;
        6)
            show_top
            echo -n "Please specify parent proxy to use (ex: 11.12.13.14:3128 ): "; read parent_proxy
            ;;
        9)
            echo;echo "Those changes are permanent!"
            echo -n "Are you sure about applying them? (y/N):"; read -n 1 answ
            [[ $answ == "y" || $answ == "Y" ]] && endconf=1
            ;;
    esac
    fi
done
}
