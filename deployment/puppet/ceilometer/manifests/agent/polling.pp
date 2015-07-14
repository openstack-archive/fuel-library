# Installs/configures the ceilometer polling agent
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
#  [*package_ensure*]
#    (optional) ensure state for package.
#    Defaults to 'present'
#
#  [*central_namespace*]
#    (optional) Use central namespace for polling agent.
#    Defaults to true.
#
#  [*compute_namespace*]
#    (optional) Use compute namespace for polling agent.
#    Defaults to true.
#
#  [*ipmi_namespace*]
#    (optional) Use ipmi namespace for polling agent.
#    Defaults to true.
#
#  [*coordination_url*]
#    (optional) The url to use for distributed group membership coordination.
#    Defaults to undef.
#

class ceilometer::agent::polling (
  $manage_service    = true,
  $enabled           = true,
  $package_ensure    = 'present',
  $central_namespace = true,
  $compute_namespace = true,
  $ipmi_namespace    = true,
  $coordination_url  = undef,
) inherits ceilometer {

  include ::ceilometer::params

  if $central_namespace {
    $central_namespace_name = 'central'
  }

  if $compute_namespace {
    if $::ceilometer::params::libvirt_group {
      User['ceilometer'] {
        groups => ['nova', $::ceilometer::params::libvirt_group]
      }
    } else {
      User['ceilometer'] {
        groups => ['nova']
      }
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

    $compute_namespace_name = 'compute'

    Package <| title == 'nova-common' |> -> Package['ceilometer-common']
  }

  if $ipmi_namespace {
    $ipmi_namespace_name = 'ipmi'
  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  $namespaces = [$central_namespace_name, $compute_namespace_name, $ipmi_namespace_name]
  $namespaces_real = inline_template('<%= @namespaces.find_all {|x| x !~ /^undef/ }.join "," %>')

  package { 'ceilometer-polling':
    ensure => $package_ensure,
    name   => $::ceilometer::params::agent_polling_package_name,
    tag    => 'openstack',
  }

  if $namespaces_real {
    ceilometer_config {
      'DEFAULT/polling_namespaces': value => $namespaces_real
    }
  }

  Ceilometer_config<||> ~> Service['ceilometer-polling']
  Package['ceilometer-polling'] -> Service['ceilometer-polling']
  Package['ceilometer-common'] -> Service['ceilometer-polling']

  service { 'ceilometer-polling':
    ensure     => $service_ensure,
    name       => $::ceilometer::params::agent_polling_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }

  if $coordination_url {
    ceilometer_config {
      'coordination/backend_url': value => $coordination_url
    }
  }
}
