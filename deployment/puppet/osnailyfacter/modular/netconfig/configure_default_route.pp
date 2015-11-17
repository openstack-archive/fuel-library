notice('MODULAR: configure_default_route.pp')

$network_scheme         = hiera('network_scheme')
$management_vrouter_vip = hiera('management_vrouter_vip')
prepare_network_config($network_scheme)
$management_int         = get_network_role_property('management', 'interface')
$fw_admin_int           = get_network_role_property('fw-admin', 'interface')

if ( $::l23_os =~ /(?i:centos6)/ and $::kernelmajversion == '3.10' ) {
  $ovs_datapath_package_name = 'kmod-openvswitch-lt'
}

class { 'l23network' :
  use_ovs                      => hiera('use_ovs', false),
  use_ovs_dkms_datapath_module => $::l23_os ? {
                                    /(?i:redhat7|centos7)/ => false,
                                    default                => true
                                  },
  ovs_datapath_package_name    => $ovs_datapath_package_name,
}

$ifconfig = configure_default_route($network_scheme, $management_vrouter_vip, $fw_admin_int, $management_int )
notice ($ifconfig)
