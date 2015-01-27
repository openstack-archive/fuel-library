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

service { 'nova-network' :
  ensure => stopped,
  enable => false,
}
