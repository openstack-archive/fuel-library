class osnailyfacter::netconfig::configure_default_route {

  notice('MODULAR: netconfig/configure_default_route.pp')

  $network_scheme         = hiera_hash('network_scheme', {})
  $management_vrouter_vip = hiera('management_vrouter_vip')
  $management_role        = 'management'
  $fw_admin_role          = 'fw-admin'

  if ( $::l23_os =~ /(?i:centos6)/ and $::kernelmajversion == '3.10' ) {
    $ovs_datapath_package_name = 'kmod-openvswitch-lt'
  }

  class { '::l23network' :
    use_ovs                      => hiera('use_ovs', false),
    use_ovs_dkms_datapath_module => $::l23_os ? {
                                      /(?i:redhat7|centos7|oraclelinux7)/ => false,
                                      default                             => true
                                    },
    ovs_datapath_package_name    => $ovs_datapath_package_name,
  }

  notice ($network_scheme)

  if !empty($network_scheme) {
    prepare_network_config($network_scheme)
    $sdn = generate_network_config()
    notify {'SDN': message => $sdn }
  }

}
