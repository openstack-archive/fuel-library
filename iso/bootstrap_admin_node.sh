#!/bin/bash

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
echo;echo "Provisioning masternode role ..."
(
puppet apply -e "class {openstack::mirantis_repos: enable_epel => true }"
puppet apply -e "class {puppet: } -> class {puppet::thin:} -> class {puppet::nginx: puppet_master_hostname => \"$hstname.$domain\"}"
puppet apply -e 'class {puppetdb: }'
puppet apply -e 'class {puppet::master_config: }'

# Walking aroung nginx's default server config
rm -f /etc/nginx/conf.d/default.conf
service nginx restart

puppet apply --debug -e  "class {cobbler: server => \"$server\", domain_name => \"$domain_name\", name_server => \"$name_server\", \
 next_server => \"$next_server\", dhcp_start_address => \"$dhcp_start_address\" , dhcp_end_address => \"$dhcp_end_address\", \
 dhcp_netmask => \"$dhcp_netmask\", dhcp_gateway => \"$dhcp_gateway\" , cobbler_user => \"$cobbler_user\", cobbler_password =>\"$cobbler_password\", \
 pxetimeout => \"$pxetimeout\", dhcp_interface => \"$dhcp_interface\" }"

puppet apply -e " \
        class { 'cobbler::nat': nat_range => \"$mgmt_ip/$mgmt_mask\" }
        cobbler_distro {'ubuntu_1204_x86_64':
            kernel    => '/var/www/ubuntu/netboot/linux',
            initrd    => '/var/www/ubuntu/netboot/initrd.gz',
            breed     => 'ubuntu',
            arch      => 'x86_64',
            osversion => 'precise',
            ksmeta    => 'tree_host=172.18.67.168 tree_url=/ubuntu-repo/mirror.yandex.ru/ubuntu/', }
        class { 'cobbler::profile::ubuntu_1204_x86_64': }
        cobbler_distro {'centos63_x86_64':
            kernel    => '/var/www/centos/6.3/os/x86_64/isolinux/vmlinuz',
            initrd    => '/var/www/centos/6.3/os/x86_64/isolinux/initrd.img',
            arch      => 'x86_64',
            breed     => 'redhat',
            osversion => 'rhel6',
            ksmeta    => 'tree=http://172.18.67.168/centos-repo/centos-6.3', }
        class { 'cobbler::profile::centos63_x86_64': }
        class { 'mcollective::rabbitmq': } class { 'mcollective::client': }"
) >> $log