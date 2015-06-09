# == Class: neutron::agents:lbaas:
#
# Setups Neutron Load Balancing agent.
#
# === Parameters
#
# [*package_ensure*]
#   (optional) Ensure state for package. Defaults to 'present'.
#
# [*enabled*]
#   (optional) Enable state for service. Defaults to 'true'.
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
# [*debug*]
#   (optional) Show debugging output in log. Defaults to false.
#
# [*interface_driver*]
#   (optional) Defaults to 'neutron.agent.linux.interface.OVSInterfaceDriver'.
#
# [*device_driver*]
#   (optional) Defaults to 'neutron.services.loadbalancer.drivers.haproxy.namespace_driver.HaproxyNSDriver'.
#
# [*use_namespaces*]
#   (optional) Allow overlapping IP (Must have kernel build with
#   CONFIG_NET_NS=y and iproute2 package that supports namespaces).
#   Defaults to true.
#
# [*user_group*]
#   (optional) The user group.
#   Defaults to $::neutron::params::nobody_user_group
#
# [*manage_haproxy_package*]
#   (optional) Whether to manage the haproxy package.
#   Disable this if you are using the puppetlabs-haproxy module
#   Defaults to true
#
class neutron::agents::lbaas (
  $package_ensure         = present,
  $enabled                = true,
  $manage_service         = true,
  $debug                  = false,
  $interface_driver       = 'neutron.agent.linux.interface.OVSInterfaceDriver',
  $device_driver          = 'neutron.services.loadbalancer.drivers.haproxy.namespace_driver.HaproxyNSDriver',
  $use_namespaces         = true,
  $user_group             = $::neutron::params::nobody_user_group,
  $manage_haproxy_package = true,
) {

  include neutron::params

  Neutron_config<||>             ~> Service['neutron-lbaas-service']
  Neutron_lbaas_agent_config<||> ~> Service['neutron-lbaas-service']

  case $device_driver {
    /\.haproxy/: {
      Package <| title == $::neutron::params::haproxy_package |> -> Package <| title == 'neutron-lbaas-agent' |>
      if $manage_haproxy_package {
        ensure_packages([$::neutron::params::haproxy_package])
      }
    }
    default: {
      fail("Unsupported device_driver ${device_driver}")
    }
  }

  # The LBaaS agent loads both neutron.ini and its own file.
  # This only lists config specific to the agent.  neutron.ini supplies
  # the rest.
  neutron_lbaas_agent_config {
    'DEFAULT/debug':              value => $debug;
    'DEFAULT/interface_driver':   value => $interface_driver;
    'DEFAULT/device_driver':      value => $device_driver;
    'DEFAULT/use_namespaces':     value => $use_namespaces;
    'haproxy/user_group':         value => $user_group;
  }

  if $::neutron::params::lbaas_agent_package {
    Package['neutron']            -> Package['neutron-lbaas-agent']
    Package['neutron-lbaas-agent'] -> Neutron_config<||>
    Package['neutron-lbaas-agent'] -> Neutron_lbaas_agent_config<||>
    package { 'neutron-lbaas-agent':
      ensure  => $package_ensure,
      name    => $::neutron::params::lbaas_agent_package,
    }
  } else {
    # Some platforms (RedHat) do not provide a neutron LBaaS agent package.
    # The neutron LBaaS agent config file is provided by the neutron package.
    Package['neutron'] -> Neutron_lbaas_agent_config<||>
  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  service { 'neutron-lbaas-service':
    ensure  => $service_ensure,
    name    => $::neutron::params::lbaas_agent_service,
    enable  => $enabled,
    require => Class['neutron'],
  }
}
