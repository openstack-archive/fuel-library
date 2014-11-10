import 'location.pp'

class { 'cs_location_test' :
  ensure => 'absent',
  node_name => $::crm_node,
}