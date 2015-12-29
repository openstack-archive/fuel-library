notice('MODULAR: hosts.pp')

$hosts_file = '/etc/hosts'
$network_metadata = hiera_hash('network_metadata')
$host_resources = network_metadata_to_hosts($network_metadata)
$messaging_host_resources = network_metadata_to_hosts($network_metadata, 'mgmt/messaging', hiera('node_name_prefix_for_messaging'))

Host {
    ensure => present,
    target => $hosts_file
}

create_resources(host, $host_resources)

$rabbitmq_bind_ip_address = get_network_role_property('mgmt/messaging', 'ipaddr')
$vip_ip_adress            = get_network_role_property('mgmt/vip', 'ipaddr')

if($vip_ip_adress != $rabbitmq_bind_ip_address) {
  create_resources(host, $messaging_host_resources)
}

