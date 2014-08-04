class mellanox_openstack::openibd {

  # Workaround for OFED upstart: ensure OFED starts before openvswitch
  if ($::osfamily == 'Debian') {
    file { '/etc/init/openibd.conf' :
        ensure => present,
        mode   => '0644',
        source => 'puppet:///modules/mellanox_openstack/openibd.conf',
    }
  }
}
