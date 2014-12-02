class mellanox_openstack::ofed_recompile {

  $ofed_recompile_script_dir = '/opt/ofed'
  $ofed_recompile_script_name = 'ofed_recompile.sh'
  $ofed_recompile_script = "${ofed_recompile_script_dir}/${ofed_recompile_script_name}"

  if ($::osfamily == 'Debian') {
    file { $ofed_recompile_script_dir :
      ensure => directory,
    }
    file { $ofed_recompile_script :
      ensure => present,
      mode   => '0644',
      require => File[$ofed_recompile_script_dir],
      source => "puppet:///modules/mellanox_openstack/${ofed_recompile_script_name}",
    }
    package { 'dkms' :
      ensure => latest
    }
    exec { 'ofed_recompile' :
      command   => "bash ${ofed_recompile_script} recompile",
      unless    => "bash ${ofed_recompile_script} status",
      path      => ['/usr/bin','/usr/sbin','/bin','/sbin','/usr/local/bin'],
      require   => [ File[$ofed_recompile_script], Package['dkms'] ],
      logoutput => true,
      notify    => Service['openibd'],
    }
    service { 'openibd' :
      ensure => "running",
      notify => Exec['restart_ovs_for_openibd'],
    }
    exec { 'restart_ovs_for_openibd' :
      command     => "service openvswitch-switch restart",
      path        => ['/usr/bin','/usr/sbin','/bin','/sbin','/usr/local/bin'],
      refreshonly => true,
    }
  }
}
