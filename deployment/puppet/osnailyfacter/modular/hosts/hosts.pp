notice('MODULAR: hosts.pp')

$hosts_file = '/etc/hosts'
$network_metadata = hiera_hash('network_metadata')
$ordinary_host_resources = network_metadata_to_hosts($network_metadata)
$live_migration_host_resources = network_metadata_to_hosts($network_metadata, 'nova/migration', hiera('compute_name_prefix_for_live_migration'))

Host {
    ensure => present,
    target => $hosts_file
}

create_resources(host, $ordinary_host_resources)
create_resources(host, $live_migration_host_resources)
