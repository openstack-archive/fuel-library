notice('MODULAR: hosts.pp')

$hosts_file = '/etc/hosts'
$host_resources = network_metadata_to_hosts(hiera_hash('network_metadata'))
$messaging_host_resources = network_metadata_to_hosts($network_metadata, 'mgmt/messaging', hiera('node_name_prefix_for_messaging'))

Host {
    ensure => present,
    target => $hosts_file
}

create_resources(host, $host_resources)
create_resources(host, $messaging_host_resources)

