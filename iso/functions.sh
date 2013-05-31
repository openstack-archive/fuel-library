#!/bin/bash

LC_CTYPE="C"
function validate_hostname {
        local hostname=$@
        local res=1
        if [[ $hostname =~ ^[.A-Za-z0-9]*$ ]]; then
                res=0
        else
                res=1
        fi
        return $res
}
function validate_ip() {
        local ip=$@
        local res=1
        if [[ $ip =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]] || [[ $ip = none ]]; then
                res=0
	else
		res=1
        fi
        return $res
}

function set_if_conf {
    echo
    echo -n "Should we use DHCP for the ${intf} interface (Y/n)?";read -n 1 dhcpsw
    if [[ $dhcpsw =~ ^[nN] ]]; then
        echo
        eval "ip=\${${intf}_ip}"
        echo -n "Enter IP address or 'none' to disable interface [$ip]: "; read val
        validate_ip $val && ip=$val
        [ -z "$ip" ] && echo "No IP entered - will use DHCP" && return
        eval ${intf}_ip="$ip"
        eval "mask=\${${intf}_mask}"
        [ -z "$mask" ] && mask="255.255.255.0"
        echo -n "Enter netmask [$mask]: "; read val
        validate_ip $val && mask=$val
        eval ${intf}_mask="$mask"
        eval "gw=\${${intf}_gw}"
        echo -n "Enter default gateway [$gw]: "; read val
        validate_ip $val && gw=$val
        eval ${intf}_gw="$gw"
        eval "dns1=\${${intf}_dns1}"
        echo -n "Enter the 1st DNS server [$dns1]: "; read val
        validate_ip $val && dns1=$val
        eval ${intf}_dns1="$dns1"
        eval "dns2=\${${intf}_dns2}"
        echo -n "Enter the 2nd DNS server [$dns2]: "; read val
        validate_ip $val && dns2=$val
        eval ${intf}_dns2="$dns2"
    else
        eval ${intf}_ip=""; eval ${intf}_mask=""; eval ${intf}_gw=""; eval ${intf}_dns1=""; eval ${intf}_dns2=""
    fi
    echo
}

function save_if_cfg {
    scrFile="/etc/sysconfig/network-scripts/ifcfg-$device"
    hwaddr=$(cat /sys/class/net/$device/address)
    [ -z $gw ] || echo GATEWAY=$gw >> /etc/sysconfig/network
    echo DEVICE=$device > $scrFile
    echo ONBOOT=yes >> $scrFile
    echo NM_CONTROLLED=no >> $scrFile
    echo HWADDR=$hwaddr >> $scrFile
    echo USERCTL=no >> $scrFile
    if [ $ip ] && [[ $ip != none ]]; then
        echo BOOTPROTO=static >> $scrFile
        echo IPADDR=$ip >> $scrFile
        echo NETMASK=$netmask >> $scrFile
        [ $dns1 ] && echo DNS1=$dns1 >> $scrFile
        [ $dns2 ] && echo DNS2=$dns2 >> $scrFile
    elif [[ $ip = none ]] ; then
        echo BOOTPROTO=dhcp >> $scrFile
        echo ONBOOT=no >> $scrFile
    else
        echo BOOTPROTO=dhcp >> $scrFile
    fi
}

function default_settings {

    hostname="fuel-pm"
    domain="localdomain"
    mgmt_if="eth0"
    mgmt_ip="10.0.0.100"
    mgmt_mask="255.255.0.0"
    ext_if="eth1"
    dhcp_start_address="10.0.0.201"
    dhcp_end_address="10.0.0.254"
    mirror_type="default"
    puppet_master_version="2.7.19-1.el6"

    # Read settings from file
    [ -f $FUELCONF ] && source $FUELCONF

}

function apply_settings {
    echo;echo "Applying settings ..."

# Let's save settings in rc file for future use
    echo "hostname=$hostname" > $FUELCONF
    echo "domain=$domain" >> $FUELCONF
    echo "dhcp_start_address=${dhcp_start_address}" >> $FUELCONF
    echo "dhcp_end_address=${dhcp_end_address}" >> $FUELCONF
    echo "mirror_type=${mirror_type}" >> $FUELCONF
    echo "parent_proxy=${parent_proxy}" >> $FUELCONF
    echo "mgmt_if=$mgmt_if" >> $FUELCONF
    echo "mgmt_ip=${mgmt_ip}" >> $FUELCONF
    echo "mgmt_mask=${mgmt_mask}" >> $FUELCONF
    echo "mgmt_gw=$mgmt_gw" >> $FUELCONF
    echo "mgmt_dns1=$mgmt_dns1" >> $FUELCONF
    echo "mgmt_dns2=$mgmt_dns2" >> $FUELCONF
    echo "ext_if=$ext_if" >> $FUELCONF
    echo "ext_ip=${ext_ip}" >> $FUELCONF
    echo "ext_mask=${ext_mask}" >> $FUELCONF
    echo "ext_gw=$ext_gw" >> $FUELCONF
    echo "ext_dns1=$ext_dns1" >> $FUELCONF
    echo "ext_dns2=$ext_dns2" >> $FUELCONF
    
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
    : ${server=$mgmt_ip}
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
    [ -z "$mgmt_ip" ] || grep -Eq "^\s*$mgmt_ip\s+$hostname" /etc/hosts || sed -i "/$mgmt_ip/d" /etc/hosts && echo "$mgmt_ip    $hostname.$domain $hostname" >> /etc/hosts
    sed -i '/kernel.hostname/d' /etc/sysctl.conf && echo "kernel.hostname=$hostname" >> /etc/sysctl.conf
    sed -i '/kernel.domainname/d' /etc/sysctl.conf && echo "kernel.domainname=$domain" >> /etc/sysctl.conf
    sed -i '/server/d' /etc/puppet/puppetdb.conf && echo "server = $hostname.$domain" >> /etc/puppet/puppetdb.conf
    service network restart
    service puppetdb restart
    sed -i "s%\(^.*address is:\).*$%\1 `ip address show $ext_if | awk '/inet / {print \$2}' | cut -d/ -f1 -`%" /etc/issue
}

function show_top {
    clear
    echo "Hostname: $hostname"
    echo "Domain: $domain"
    echo "PXE dhcp range: ${dhcp_start_address} - ${dhcp_end_address}"
    echo "Mirror set to use: ${mirror_type}"
    echo -n "Parent proxy: "
    if [ -z "${parent_proxy}" ];then 
        echo "none (direct access)"
    else
        echo $parent_proxy
    fi
    column -t -s% <(
        echo "Management interface: $mgmt_if%External interface: $ext_if"
        echo "IP address: ${mgmt_ip:-"DHCP"}%IP address: ${ext_ip:-"DHCP"}"
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
    echo "1. Change MasterNode hostname and domain"
    echo "2. Configure OpenStack cloud management interface"
    echo "3. Configure external interface to access package repositories and Internet"
    echo "4. Change dhcp IP range to use for baremetal provisioning via PXE"
    echo "5. Choose a set of mirrors to use ('default' or 'custom')"
    echo "6. Configure MasterNode to use a parent proxy"
    echo "9. Quit"
    echo -n "Please select an action to do:"
}

function menu_conf {
    if [ -f /root/fuel.defaults ]; then
        source /root/fuel.defaults
        endconf=1
    else
        while [ $endconf -ne 1 ]; do
            show_top
            show_msg
            read -n 1 -t 5 answer

            case $answer in
            1)
                show_top
                echo "WARNING! Changing MasterNode hostname or domain name will make your existing"
                echo "puppet keys and configuration files invalid!!!"
                echo "If you have already deployed any nodes using current hostname or domain name"
                echo "you have either to re-deploy existing nodes including operating system"
                echo "installation or manually remove puppet cache and keys on every deployed node"
                echo "with 'rm -rf /var/lib/puppet' and manually change all affected puppet and"
                echo "mcollective configuration files!"
                echo "If there are no deployed nodes in your current installation - then it is safe"
                echo "to change MasterNode hostname and domain name."
                echo "This script will remove current puppet master key automatically."
                echo
                echo -n "Please enter hostname for this puppetmaster/cobbler MasterNode [$hostname]: "; read val
                [ -z "$val" ] || hostname=$val
                echo -n "Please enter domain name for this OpenStack cloud [$domain]: "; read val
                [ -z "$val" ] || domain=$val
                ;;
            2)
                show_top
                echo -n "Please specify the network interface to use for management network [${mgmt_if}]: "; read val
                [ -z "$val" ] || mgmt_if=$val
                intf="mgmt"
                set_if_conf
                ;;
            3)
                show_top
                echo -n "Please specify the network interface to access package repositories and Internet [${ext_if}]: "; read val
                [ -z "$val" ] || ext_if=$val
                intf="ext"
                set_if_conf
                ;;
            4)
                show_top
                echo -n "Please enter PXE dhcp start address [${dhcp_start_address}]: "; read val
                validate_ip $val && dhcp_start_address=$val
                echo -n "Please enter PXE dhcp end address [${dhcp_end_address}]: "; read val
                validate_ip $val && dhcp_end_address=$val
                ;;
            5)
                show_top
                echo -n "Please type a set of mirrors to use ('default' or 'custom') [${mirror_type}]: "; read val
                if [ -n "$val" ]; then
                    [[ "$val" == "default" || "$val" == "custom" ]] && mirror_type=$val
                fi
                ;;
            6)
                show_top
                echo -n "Please specify MasterNode parent proxy address and port to be used (ex: 11.12.13.14:3128 ) [${parent_proxy}]: "; read val
                [ -z "$val" ] || parent_proxy=$val
                ;;
            9)
                echo;echo "ATTENTION! The changes are permanent!"
                echo -n "Are you sure about applying them? (y/N):"; read -n 1 answ
                [[ $answ =~ ^[yY] ]] && endconf=1
                ;;
            esac
        done
    fi
}
