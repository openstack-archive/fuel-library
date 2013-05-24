#!/bin/bash

FUELCONF=/etc/fuel.conf
source /usr/local/lib/functions.sh

log="/var/log/firstboot-puppet.log"
endconf=0

curTTY=`tty`
set +x
exec <$curTTY >$curTTY 2>&1

# Applying default visible settings
default_settings

# Invoking menu for masternode configuration
menu_conf

# Applying configurations
apply_settings

# Installing puppetmaster/cobbler node role
echo;echo "Provisioning Master Node role ..."
(
mkdir -p /var/lib/puppet/ssh_keys
[ -f /var/lib/puppet/ssh_keys/openstack ] || ssh-keygen -f /var/lib/puppet/ssh_keys/openstack -N ''
chown root:puppet /var/lib/puppet/ssh_keys/openstack*
chmod g+r /var/lib/puppet/ssh_keys/openstack*
puppet apply -e "
    class {openstack::mirantis_repos: enable_epel => false } ->
    class {puppet: puppet_master_version => \"$puppet_master_version\"} -> class {puppet::thin:} -> class {puppet::nginx: puppet_master_hostname => \"$hostname.$domain\"}
    "
puppet apply -e "
    class {puppet::fileserver_config: } "
puppet apply -e "
    class {puppetdb: }"
puppetdb-ssl-setup
service puppetdb restart
puppet apply -e "
    class {puppetdb::master::config: puppet_service_name=>'thin'} "
service thin restart

# Walking aroung nginx's default server config
rm -f /etc/nginx/conf.d/default.conf
service nginx restart

puppet apply -e "
    class { cobbler: 
        server => \"$server\", 
        domain_name => \"$domain_name\",
        name_server => \"$name_server\",
        next_server => \"$next_server\",
        dhcp_start_address => \"$dhcp_start_address\",
        dhcp_end_address => \"$dhcp_end_address\",
        dhcp_netmask => \"$dhcp_netmask\",
        dhcp_gateway => \"$dhcp_gateway\",
        cobbler_user => \"$cobbler_user\",
        cobbler_password =>\"$cobbler_password\",
        pxetimeout => \"$pxetimeout\",
        dhcp_interface => \"$dhcp_interface\" }"

puppet apply -e "
    class { 'cobbler::nat': nat_range => \"$mgmt_ip/$mgmt_mask\" }
    cobbler_distro {'ubuntu_1204_x86_64':
        kernel    => '/var/www/ubuntu/netboot/linux',
        initrd    => '/var/www/ubuntu/netboot/initrd.gz',
        breed     => 'ubuntu',
        arch      => 'x86_64',
        osversion => 'precise',
        ksmeta    => 'tree_host=us.archive.ubuntu.com tree_url=/ubuntu', }
    class { 'cobbler::profile::ubuntu_1204_x86_64': }
    cobbler_distro {'centos64_x86_64':
        kernel    => '/var/www/centos/6.4/os/x86_64/isolinux/vmlinuz',
        initrd    => '/var/www/centos/6.4/os/x86_64/isolinux/initrd.img',
        arch      => 'x86_64',
        breed     => 'redhat',
        osversion => 'rhel6',
        ksmeta    => 'tree=http://download.mirantis.com/centos-6.4', }
    class { 'cobbler::profile::centos64_x86_64': }"

puppet apply -e '
    $stompuser="mcollective"
    $stomppassword="AeN5mi5thahz2Aiveexo"
    $pskey="un0aez2ei9eiGaequaey4loocohjuch4Ievu3shaeweeg5Uthi"
    $stomphost="127.0.0.1"
    $stompport="61613"

    class { mcollective::rabbitmq:
	stompuser => $stompuser,
	stomppassword => $stomppassword,
    }

    class { mcollective::client:
	pskey => $pskey,
	stompuser => $stompuser,
	stomppassword => $stomppassword,
	stomphost => $stomphost,
	stompport => $stompport
    } '

# Configuring squid with or without parent proxy
if [[ -n "$parent_proxy" ]];then
  IFS=: read server port <<< "$parent_proxy"
  puppet apply -e "
  \$squid_cache_parent = \"$server\"
  \$squid_cache_parent_port = \"$port\"
  class { squid: }"
else
  puppet apply -e "class { squid: }"
fi

iptables -A PREROUTING -t nat -i $mgmt_if -s $mgmt_ip/$mgmt_mask ! -d $mgmt_ip -p tcp --dport 80 -j REDIRECT --to-port 3128

/etc/init.d/iptables save

) >> $log 2>&1
