#<task>
#- id: vmware-compute
#  type: puppet
#  groups: [compute]
#  required_for: [deploy]
#  requires: [hiera, globals, netconfig, firewall]
#  parameters:
#  puppet_manifest: /etc/puppet/modules/osnailyfacter/modular/vmware/compute.pp
#  puppet_modules: /etc/puppet/modules
#  timeout: 3600
#</task>
# requires: compute?
$use_vcenter = hiera('use_vcenter', false)

include nova::params

if $use_vcenter{
  nova_config { 'DEFAULT/multi_host': value => 'False' } -> Service['nova-network']
  service { 'nova-network' :
    name   => $::nova::params::network_service_name,
    ensure => stopped,
    enable => false,
  }
}
