notice('MODULAR: conntrackd.pp')

prepare_network_config(hiera('network_scheme', { }))
$vrouter_name = hiera('vrouter_name', 'pub')
$bind_address = get_network_role_property('mgmt/vip', 'ipaddr')

# CONNTRACKD for CentOS 6 doesn't work under namespaces
if $operatingsystem == 'Ubuntu' {
  class { 'cluster::conntrackd_ocf' :
    vrouter_name => $vrouter_name,
    bind_address => $bind_address,
  }
}
