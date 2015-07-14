#The ceilometer::agent::compute class installs the ceilometer compute agent
# Include this class on all nova compute nodes
#
# == Parameters
#  [*enabled*]
#    (optional) Should the service be enabled.
#    Defaults to true.
#
#  [*manage_service*]
#    (optional)  Whether the service should be managed by Puppet.
#    Defaults to true.
#
# [*package_ensure*]
#   (optional) ensure state for package.
#   Defaults to 'present'
#
class ceilometer::agent::compute (
  $manage_service   = true,
  $enabled          = true,
  $package_ensure   = 'present',
) inherits ceilometer {

  warning('This class is deprecated. Please use ceilometer::agent::polling with compute namespace instead.')

  include ::ceilometer::params

  Ceilometer_config<||> ~> Service['ceilometer-agent-compute']

  Package['ceilometer-agent-compute'] -> Service['ceilometer-agent-compute']
  package { 'ceilometer-agent-compute':
    ensure => $package_ensure,
    name   => $::ceilometer::params::agent_compute_package_name,
    tag    => 'openstack',
  }

  if $::ceilometer::params::libvirt_group {
    User['ceilometer'] {
      groups => ['nova', $::ceilometer::params::libvirt_group]
    }
  } else {
    User['ceilometer'] {
      groups => ['nova']
    }
  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  Package <| title == 'nova-common' |> -> Package['ceilometer-common'] -> Service['ceilometer-agent-compute']
  service { 'ceilometer-agent-compute':
    ensure     => $service_ensure,
    name       => $::ceilometer::params::agent_compute_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }

  #NOTE(dprince): This is using a custom (inline) file_line provider
  # until this lands upstream:
  # https://github.com/puppetlabs/puppetlabs-stdlib/pull/174
  Nova_config<| |> {
    before +> File_line_after[
      'nova-notification-driver-common',
      'nova-notification-driver-ceilometer'
    ],
  }

  file_line_after {
    'nova-notification-driver-common':
      line   =>
        'notification_driver=nova.openstack.common.notifier.rpc_notifier',
      path   => '/etc/nova/nova.conf',
      after  => '^\s*\[DEFAULT\]',
      notify => Service['nova-compute'];
    'nova-notification-driver-ceilometer':
      line   => 'notification_driver=ceilometer.compute.nova_notifier',
      path   => '/etc/nova/nova.conf',
      after  => '^\s*\[DEFAULT\]',
      notify => Service['nova-compute'];
  }

}
