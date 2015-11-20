notice('MODULAR: hosts.pp')

$hosts_file = '/etc/hosts'
$host_resources = network_metadata_to_hosts(hiera_hash('network_metadata'))

Host {
    ensure => present,
    target => $hosts_file
}

create_resources(host, $host_resources)

