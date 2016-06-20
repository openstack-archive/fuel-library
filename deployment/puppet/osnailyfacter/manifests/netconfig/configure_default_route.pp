class osnailyfacter::netconfig::configure_default_route {

  notice('MODULAR: netconfig/configure_default_route.pp')

  $network_scheme         = hiera_hash('network_scheme', {})
  $management_vrouter_vip = hiera('management_vrouter_vip')
  $management_role        = 'management'
  $fw_admin_role          = 'fw-admin'

  $dpdk_options = hiera_hash('dpdk', {})

  if ($::l23_os =~ /(?i:redhat7|centos7)/) {
    # do not install
    $ovs_datapath_package_name = false
  } elsif $::l23_os =~ /(?i:centos6)/ and $::kernelmajversion == '3.10' {
    # install more specific version for Centos6 AND 3.10 kernel
    $ovs_datapath_package_name = 'kmod-openvswitch-lt'
  } else {
    # do not change default behavior
    $ovs_datapath_package_name = undef
  }

  class { '::l23network' :
    use_ovs                      => hiera('use_ovs', false),
    ovs_datapath_package_name    => $ovs_datapath_package_name,
    use_dpdk                     => pick($dpdk_options['enabled'], false),
    dpdk_options                 => $dpdk_options,
  }

  $new_network_scheme = configure_default_route($network_scheme, $management_vrouter_vip, $fw_admin_role, $management_role )
  notice ($new_network_scheme)

  if !empty($new_network_scheme) {
    prepare_network_config($new_network_scheme)
    $sdn = generate_network_config()
    notify {'SDN': message => $sdn }
  }

}
