# manage /etc/hosts
#
define osnailyfacter::hosts_file (
  $nodes_hash,
  $network_role = 'mgmt/vip',
  $name_prefix  = '',
  $name_suffix  = '',
  $aliases      = true,
  $hosts_file   = '/etc/hosts'
) {

  $host_resources = nodes_hash_to_hosts($nodes_hash, $network_role, $aliases, $name_prefix, $name_suffix)

  Host {
    ensure => present,
    target => $hosts_file
  }

  create_resources(host, $host_resources)
}
