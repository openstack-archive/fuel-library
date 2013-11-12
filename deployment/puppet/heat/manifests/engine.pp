class heat::engine (
  $pacemaker             = false,
  $ocf_scripts_dir       = '/usr/lib/ocf/resource.d',
  $ocf_scripts_provider  = 'mirantis',
) {

  include heat::params

  validate_string($keystone_password)
  $service_name = $::heat::params::engine_service_name
  $package_name = $::heat::params::engine_package_name

  package { 'heat-engine' :
    ensure => installed,
    name   => $package_name,
  }

  if !$pacemaker {

    # standard service mode

    service { 'heat-engine':
      ensure     => 'running',
      name       => $service_name,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
    }

  } else {

    # pacemaker resource mode

    if $::osfamily == 'RedHat' {
      $ocf_script_template = 'heat_engine_centos.ocf.erb'
    } else {
      $ocf_script_template = 'heat_engine_ubuntu.ocf.erb'
    }

    file { 'heat-engine-ocf' :
      ensure  => present,
      path    => "${ocf_scripts_dir}/${ocf_scripts_provider}/${service_name}",
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      content => template("heat/${ocf_script_template}"),
    }

    service { 'heat-engine':
      ensure     => 'running',
      name       => $service_name,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
      provider   => 'pacemaker',
    }

    cs_shadow { $service_name :
      cib => $service_name,
    }

    cs_commit { $service_name :
      cib => $service_name,
    }

    corosync::cleanup { $service_name : }

    cs_resource { $service_name :
      ensure          => present,
      cib             => $service_name,
      primitive_class => 'ocf',
      provided_by     => $ocf_scripts_provider,
      primitive_type  => $service_name,
      operations   => {
        'monitor'  => { 'interval' => '20', 'timeout'  => '30' },
        'start'    => { 'timeout' => '60' },
        'stop'     => { 'timeout' => '60' },
      },
    }

    File['heat-engine-ocf'] -> Cs_shadow[$service_name] -> Cs_resource[$service_name] -> Cs_commit[$service_name] ~> Corosync::Cleanup[$service_name] -> Service['heat-engine']

  }

  exec {'heat-encryption-key-replacement':
    command => 'sed -i "s/%ENCRYPTION_KEY%/`hexdump -n 16 -v -e \'/1 "%02x"\' /dev/random`/" /etc/heat/heat-engine.conf',
    path    => [ '/usr/bin', '/bin' ],
    onlyif  => 'grep -c ENCRYPTION_KEY /etc/heat/heat-engine.conf',
  }

  Package['heat-common'] -> Package['heat-engine'] -> File['/etc/heat/heat.conf'] -> Heat_config<||> ~> Service['heat-engine']
  File['/etc/heat/heat.conf'] -> Exec['heat-encryption-key-replacement'] -> Service['heat-engine']
  File['/etc/heat/heat.conf'] ~> Service['heat-engine']
  Class['heat::db'] -> Service['heat-engine']
  Heat_config<||> -> Exec['heat_db_sync'] -> Service['heat-engine']

}
