import 'location.pp'

class { 'cs_location_test' :
  ensure => 'present',
  node_name => $::crm_node,
}