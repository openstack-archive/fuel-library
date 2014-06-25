class heat::engine (
  $pacemaker             = false,
  $primary_controller    = false,
  $ocf_scripts_dir       = '/usr/lib/ocf/resource.d',
  $ocf_scripts_provider  = 'mirantis',
) {

  include heat::params

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

    if $primary_controller {
      cs_resource { $service_name :
        ensure          => present,
        primitive_class => 'ocf',
        provided_by     => $ocf_scripts_provider,
        primitive_type  => $service_name,
        metadata        => { 'resource-stickiness' => '1' },
        operations   => {
          'monitor'  => { 'interval' => '20', 'timeout'  => '30' },
          'start'    => { 'timeout' => '60' },
          'stop'     => { 'timeout' => '60' },
        },
      }

      Heat_config<||> -> File['heat-engine-ocf'] -> Cs_resource[$service_name] -> Service['heat-engine']
    } else {

      Heat_config<||> -> File['heat-engine-ocf'] -> Service['heat-engine']

    }

    service { 'heat-engine':
      ensure     => 'running',
      name       => $service_name,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
      provider   => 'pacemaker',
    }


  }

  exec {'heat-encryption-key-replacement':
    command => 'sed -i "s/%ENCRYPTION_KEY%/`hexdump -n 16 -v -e \'/1 "%02x"\' /dev/random`/" /etc/heat/heat.conf',
    path    => [ '/usr/bin', '/bin' ],
    onlyif  => 'grep -c ENCRYPTION_KEY /etc/heat/heat.conf',
  }

  Package['heat-common'] -> Package['heat-engine'] -> File['/etc/heat/heat.conf'] -> Heat_config<||> ~> Service['heat-engine']
  File['/etc/heat/heat.conf'] -> Exec['heat-encryption-key-replacement'] -> Service['heat-engine']
  File['/etc/heat/heat.conf'] ~> Service['heat-engine']
  Class['heat::db'] -> Service['heat-engine']
  Heat_config<||> -> Exec['heat_db_sync'] -> Service['heat-engine']
  Package<| title == 'heat-engine'|> ~> Service<| title == 'heat-engine'|>
  if !defined(Service['heat-engine']) {
    notify{ "Module ${module_name} cannot notify service heat-engine on package update": }
  }
}
