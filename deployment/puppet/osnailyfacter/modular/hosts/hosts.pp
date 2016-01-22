notice('MODULAR: hosts.pp')

$hosts_file = '/etc/hosts'
$network_metadata = hiera_hash('network_metadata')
$host_resources = network_metadata_to_hosts($network_metadata)
$messaging_host_resources = network_metadata_to_hosts($network_metadata, 'mgmt/messaging', hiera('node_name_prefix_for_messaging'))

Host {
    ensure => present,
    target => $hosts_file
}

create_resources(host, merge($host_resources, $messaging_host_resources))

