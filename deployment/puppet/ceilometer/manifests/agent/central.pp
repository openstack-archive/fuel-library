# Installs/configures the ceilometer central agent
#
# == Parameters
#  [*auth_url*]
#    Keystone URL. Optional. Defaults to 'http://localhost:5000/v2.0'
#
#  [*auth_region*]
#    Keystone region. Optional. Defaults to 'RegionOne'
#
#  [*auth_user*]
#    Keystone user for ceilometer. Optional. Defaults to 'ceilometer'
#
#  [*auth_password*]
#    Keystone password for ceilometer. Optional. Defaults to 'password'
#
#  [*auth_tenant_name*]
#    Keystone tenant name for ceilometer. Optional. Defauls to 'services'
#
#  [*auth_tenant_id*]
#    Keystone tenant id for ceilometer. Optional. Defaults to ''
#
#  [*enabled*]
#    Should the service be enabled. Optional. Defauls to true
#
class ceilometer::agent::central (
  $auth_host         = 'http://localhost:5000/v2.0',
  $auth_region      = 'RegionOne',
  $auth_user        = 'ceilometer',
  $auth_password    = 'password',
  $auth_tenant_name = 'services',
  $auth_tenant_id   = '',
  $enabled          = true,
  $ha_mode          = false,
) {

  include ceilometer::params

  Ceilometer_config<||> ~> Service['ceilometer-agent-central']
  Package['ceilometer-common'] -> Service['ceilometer-agent-central']
  Package['ceilometer-agent-central'] -> Service['ceilometer-agent-central']

  package { 'ceilometer-agent-central':
    ensure => installed,
    name   => $::ceilometer::params::agent_central_package_name,
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  ceilometer_config {
    'DEFAULT/os_auth_url'         : value => "http://${auth_host}:5000/v2.0";
    'DEFAULT/os_auth_region'      : value => $auth_region;
    'DEFAULT/os_username'         : value => $auth_user;
    'DEFAULT/os_password'         : value => $auth_password;
    'DEFAULT/os_tenant_name'      : value => $auth_tenant_name;
  }

  if ($auth_tenant_id != '') {
    ceilometer_config {
      'DEFAULT/os_tenant_id'        : value => $auth_tenant_id;
    }
  }

  if $ha_mode {

    $res_name = "p_${::ceilometer::params::agent_central_service_name}"
    $cib_name = "${::ceilometer::params::agent_central_service_name}"

    Package['pacemaker'] -> File['ceilometer-agent-central-ocf']
    file {'ceilometer-agent-central-ocf':
      path=>'/usr/lib/ocf/resource.d/mirantis/ceilometer-agent-central',
      mode => 755,
      owner => root,
      group => root,
      source => 'puppet:///modules/ceilometer/ocf/ceilometer-agent-central',
    }

    File['ceilometer-agent-central-ocf'] -> Cs_resource[$res_name]
    cs_resource { $res_name:
      ensure          => present,
      cib             => $cib_name,
      primitive_class => 'ocf',
      provided_by     => 'mirantis',
      primitive_type  => 'ceilometer-agent-central',
      metadata        => { 'target-role' => 'stopped' },
      parameters      => { 'user' => 'ceilometer' },
      operations      => {
        'monitor'  => {
          'interval' => '20',
          'timeout'  => '30'
        }
        ,
        'start'    => {
          'timeout' => '360'
        }
        ,
        'stop'     => {
          'timeout' => '360'
        }
      },
    }

    cs_shadow { $res_name: cib => $cib_name }
    cs_commit { $res_name: cib => $cib_name }

    ::corosync::cleanup{ $res_name: }

    service { 'ceilometer-agent-central':
      ensure     => $service_ensure,
      name       => $res_name,
      enable     => $enabled,
      hasstatus  => true,
      hasrestart => true,
      provider   => "pacemaker",
    }

    Cs_commit[$res_name] -> ::Corosync::Cleanup[$res_name]
    Cs_commit[$res_name] ~> ::Corosync::Cleanup[$res_name]

    Cs_shadow[$res_name] ->
      Cs_resource[$res_name] ->
        Cs_commit[$res_name] ->
          Service['ceilometer-agent-central']

  } else {

    service { 'ceilometer-agent-central':
      ensure     => $service_ensure,
      name       => $::ceilometer::params::agent_central_service_name,
      enable     => $enabled,
      hasstatus  => true,
      hasrestart => true,
    }

  }
}
