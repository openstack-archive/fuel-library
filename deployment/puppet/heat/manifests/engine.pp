# Class heat::engine
#
#  Installs & configure the heat engine service
#
# == parameters
#  [*enabled*]
#    (optional) The state of the service
#    Defaults to true
#
#  [*heat_stack_user_role*]
#    (optional) Keystone role for heat template-defined users
#    Defaults to 'heat_stack_user'
#
#  [*heat_metadata_server_url*]
#    (optional) URL of the Heat metadata server
#    Defaults to 'http://127.0.0.1:8000'
#
#  [*heat_waitcondition_server_url*]
#    (optional) URL of the Heat waitcondition server
#    Defaults to 'http://127.0.0.1:8000/v1/waitcondition'
#
#  [*heat_watch_server_url*]
#    (optional) URL of the Heat cloudwatch server
#    Defaults to 'http://127.0.0.1:8003'
#
#  [*auth_encryption_key*]
#    (required) Encryption key used for authentication info in database
#

class heat::engine (
  $pacemaker                     = false,
  $ocf_scripts_dir               = '/usr/lib/ocf/resource.d',
  $ocf_scripts_provider          = 'mirantis',
  $auth_encryption_key,
  $enabled                       = true,
  $heat_stack_user_role          = 'heat_stack_user',
  $heat_metadata_server_url      = 'http://127.0.0.1:8000',
  $heat_waitcondition_server_url = 'http://127.0.0.1:8000/v1/waitcondition',
  $heat_watch_server_url         = 'http://127.0.0.1:8003',
) {

  include heat::params

  $service_name = $::heat::params::engine_service_name
  $package_name = $::heat::params::engine_package_name

  Heat_config<||> ~> Service['heat-engine']

  Package['heat-engine'] -> Heat_config<||>
  Package['heat-engine'] -> Service['heat-engine']
  package { 'heat-engine':
    ensure => installed,
    name   => $package_name,
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  if !$pacemaker {

    # standard service mode

    service { 'heat-engine':
      ensure     => $service_ensure,
      name       => $service_name,
      enable     => $enabled,
      hasstatus  => true,
      hasrestart => true,
      require    => [ File['/etc/heat/heat.conf'],
                      Package['heat-common'],
                      Package['heat-engine']],
      subscribe  => Exec['heat-dbsync'],
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
      ensure     => $service_ensure,
      name       => $service_name,
      enable     => $enabled,
      hasstatus  => true,
      hasrestart => true,
      provider   => 'pacemaker',
      require    => [ File['/etc/heat/heat.conf'],
                      Package['heat-common'],
                      Package['heat-engine']],
      subscribe  => Exec['heat-dbsync'],
    }

    cs_shadow { $service_name :
      cib => $service_name,
    }

    cs_commit { $service_name :
      cib => $service_name,
    }

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

    Heat_config<||> -> File['heat-engine-ocf'] -> Cs_shadow[$service_name] -> Cs_resource[$service_name] -> Cs_commit[$service_name] -> Service['heat-engine']

  }

  exec {'heat-encryption-key-replacement':
    command => 'sed -i "s/%ENCRYPTION_KEY%/`hexdump -n 16 -v -e \'/1 "%02x"\' /dev/random`/" /etc/heat/heat.conf',
    path    => [ '/usr/bin', '/bin' ],
    onlyif  => 'grep -c ENCRYPTION_KEY /etc/heat/heat.conf',
  }

  heat_config {
    'DEFAULT/auth_encryption_key'          : value => $auth_encryption_key;
    'DEFAULT/heat_stack_user_role'         : value => $heat_stack_user_role;
    'DEFAULT/heat_metadata_server_url'     : value => $heat_metadata_server_url;
    'DEFAULT/heat_waitcondition_server_url': value => $heat_waitcondition_server_url;
    'DEFAULT/heat_watch_server_url'        : value => $heat_watch_server_url;
  }

  File['/etc/heat/heat.conf'] -> Exec['heat-encryption-key-replacement'] -> Service['heat-engine']
  Package<| title == 'heat-engine'|> ~> Service<| title == 'heat-engine'|>
  if !defined(Service['heat-engine']) {
    notify{ "Module ${module_name} cannot notify service heat-engine on package update": }
  }
}
