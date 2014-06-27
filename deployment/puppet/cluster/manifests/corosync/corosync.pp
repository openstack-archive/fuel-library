# Not a doc string
class neutron::fuel_extras::corosync (
  #keystone attrs
  $admin_password    = 'asdf123',
  $admin_tenant_name = 'services',
  $admin_username    = 'neutron',
  $auth_url          = 'http://localhost:35357/v2.0',

  #Services to manage
  $ovs_ha = true,
  $metadata_ha = true,
  $l3_ha = true,
  $dhcp_ha = true,

  #Other attrs
  $debug = false
  )
{
  include ::neutron::params

  class {'neutron::agents::ovs': }
  class {'neutron::agents::metadata':
    auth_password => 'asdf',
    shared_secret => 'zBaC0anS'
  }
  class {'neutron::agents::dhcp': }
  class {'neutron::agents::l3': }

  class {'neutron':
    rabbit_password => 'e6apye6c',
  }
  $debug = false
  ###### END HARD CODES FOR POC #####




  if $metadata_ha {
  } # End metadata_ha

  if $dhcp_ha {
  } # End dhcp_ha

  if $l3_ha {
 
  } # End l3_ha

}
