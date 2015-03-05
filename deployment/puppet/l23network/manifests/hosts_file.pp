# manage /etc/hosts
#
class l23network::hosts_file (
  $nodes,
  $hosts_file = '/etc/hosts'
) {

  #Move original hosts file

  $host_resources = nodes_to_hosts($nodes)

  Host {
    ensure => present,
    target => $hosts_file
  }

  create_resources(host, $host_resources)
}
