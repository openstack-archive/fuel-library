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
#  [*ha_mode*]
#    Should we deploy service in HA mode. Active/Passive mode under pacemaker.
#    Optional. Defauls to false
#
class ceilometer::agent::central (
  $auth_host          = 'http://localhost:5000/v2.0',
  $auth_region        = 'RegionOne',
  $auth_user          = 'ceilometer',
  $auth_password      = 'password',
  $auth_tenant_name   = 'services',
  $auth_tenant_id     = '',
  $enabled            = true,
  $ha_mode            = false,
  $primary_controller = false
) {

  include ceilometer::params

  Ceilometer_config<||> ~> Service['ceilometer-agent-central']

  package { 'ceilometer-agent-central':
    ensure => installed,
    name   => $::ceilometer::params::agent_central_package_name,
  }

  tweaks::ubuntu_service_override { 'ceilometer-agent-central' :}

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

    Package['pacemaker'] -> File['ceilometer-agent-central-ocf']
    Package['ceilometer-common'] -> File['ceilometer-agent-central-ocf']
    Package['ceilometer-agent-central'] -> File['ceilometer-agent-central-ocf']

    file {'ceilometer-agent-central-ocf':
      path   =>'/usr/lib/ocf/resource.d/mirantis/ceilometer-agent-central',
      mode   => '0755',
      owner  => root,
      group  => root,
      source => 'puppet:///modules/ceilometer/ocf/ceilometer-agent-central',
    }

    if $primary_controller {
      cs_resource { $res_name:
        ensure          => present,
        primitive_class => 'ocf',
        provided_by     => 'mirantis',
        primitive_type  => 'ceilometer-agent-central',
        metadata        => { 'target-role' => 'stopped', 'resource-stickiness' => '1' },
        parameters      => { 'user' => 'ceilometer' },
        operations      => {
          'monitor'  => {
            'interval' => '20',
            'timeout'  => '30'
          },
          'start'    => {
            'timeout' => '360'
          },
          'stop'     => {
            'timeout' => '360'
          }
        },
      }
      File['ceilometer-agent-central-ocf'] -> Cs_resource[$res_name] -> Service['ceilometer-agent-central']
    } else {
      File['ceilometer-agent-central-ocf'] -> Service['ceilometer-agent-central']
    }

    service { 'ceilometer-agent-central':
      ensure     => $service_ensure,
      name       => $res_name,
      enable     => $enabled,
      hasstatus  => true,
      hasrestart => true,
      provider   => "pacemaker",
    }

  } else {

    Package['ceilometer-common'] -> Service['ceilometer-agent-central']
    Package['ceilometer-agent-central'] -> Service['ceilometer-agent-central']
    service { 'ceilometer-agent-central':
      ensure     => $service_ensure,
      name       => $::ceilometer::params::agent_central_service_name,
      enable     => $enabled,
      hasstatus  => true,
      hasrestart => true,
    }

  }
  Package<| title == 'ceilometer-agent-central' or title == 'ceilometer-common'|> ~>
  Service<| title == 'ceilometer-agent-central'|>
  if !defined(Service['ceilometer-agent-central']) {
    notify{ "Module ${module_name} cannot notify service ceilometer-agent-central\
 on packages update": }
  }
}
