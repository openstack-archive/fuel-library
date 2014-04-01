# This is the main VMWare integration class
# It should check the variables and basing on them call needed subclasses in order to setup VMWare integration with OpenStack
# Variables:
# vcenter_user - contents user name which should be used for configuring integration with vCenter
# vcenter_password - vCenter user password
# vcenter_host_ip - contents IP address of the vCenter host
# vcenter_cluster - contents vCenter cluster name (multi-cluster is not supported yet)
# use_quantum - shows if neutron enabled

class vmware (

  $vcenter_user = 'user',
  $vcenter_password = 'password',
  $vcenter_host_ip = '10.10.10.10',
  $vcenter_cluster = 'cluster',
  $use_quantum = false,

)

{ # begin of class

  class { 'vmware::controller':
    vcenter_user => $vcenter_user,
    vcenter_password => $vcenter_password,
    vcenter_host_ip => $vcenter_host_ip,
    vcenter_cluster => $vcenter_cluster,
    use_quantum => $use_quantum,
  }

} # end of class
