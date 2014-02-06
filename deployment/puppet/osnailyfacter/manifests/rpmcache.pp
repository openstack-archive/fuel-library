class osnailyfacter::rpmcache {

  $rh_base_channels = "rhel-6-server-rpms rhel-6-server-optional-rpms rhel-lb-for-rhel-6-server-rpms rhel-rs-for-rhel-6-server-rpms rhel-ha-for-rhel-6-server-rpms rhel-server-ost-6-folsom-rpms"
  $rh_openstack_channel = "rhel-6-server-openstack-4.0-rpms"

  $sat_base_channels = "rhel-x86_64-server-6 rhel-x86_64-server-optional-6 rhel-x86_64-server-lb-6 rhel-x86_64-server-rs-6 rhel-x86_64-server-ha-6"
  $sat_openstack_channel = "rhel-x86_64-server-6-ost-4"

  class { 'rpmcache::rpmcache':
    releasever            => '6Server',
    pkgdir                => '/var/www/nailgun/rhel/6.5/nailgun/x86_64',
    rh_username           => $::fuel_settings['rh_username'],
    rh_password           => $::fuel_settings['rh_password'],
    rh_base_channels      => $rh_base_channels,
    rh_openstack_channel  => $rh_openstack_channel,
    use_satellite         => $::fuel_settings['use_satellite'],
    sat_hostname          => $::fuel_settings['sat_hostname'],
    activation_key        => $::fuel_settings['activation_key'],
    sat_base_channels     => $sat_base_channels,
    sat_openstack_channel => $sat_openstack_channel

  }

}
