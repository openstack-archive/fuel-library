class osnailyfacter::hosts::hosts {

  notice('MODULAR: hosts/hosts.pp')

  $hosts_file = '/etc/hosts'
  $network_metadata = hiera_hash('network_metadata')
  $messaging_prefix = hiera('node_name_prefix_for_messaging')
  $host_resources = network_metadata_to_hosts($network_metadata)
  $messaging_host_resources = network_metadata_to_hosts($network_metadata, 'mgmt/messaging', $messaging_prefix)
  $host_hash = merge($host_resources, $messaging_host_resources)

  file { $hosts_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('osnailyfacter/hosts.erb'),
  }

}
