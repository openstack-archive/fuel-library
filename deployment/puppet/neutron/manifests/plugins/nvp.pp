#
# Configure the Nicira NVP plugin for neutron.
#
# === Parameters
#
# [*nvp_controllers*]
#   The password for connection to VMware vCenter server.
#
# [*nvp_user*]
#   The user name for NVP controller.
#
# [*nvp_password*]
#   The password for NVP controller
#
# [*default_tz_uuid*]
#   UUID of the pre-existing default NVP Transport zone to be used for creating
#   tunneled isolated "Neutron" networks. This option MUST be specified.
#
# [*default_l3_gw_service_uuid*]
#   (Optional) UUID for the default l3 gateway service to use with this cluster.
#   To be specified if planning to use logical routers with external gateways.
#   Defaults to None.
#
class neutron::plugins::nvp (
  $default_tz_uuid,
  $nvp_controllers,
  $nvp_user,
  $nvp_password,
  $default_l3_gw_service_uuid = undef,
  $package_ensure    = 'present'
) {

  include neutron::params

  Package['neutron'] -> Package['neutron-plugin-nvp']
  Package['neutron-plugin-nvp'] -> Neutron_plugin_nvp<||>
  Neutron_plugin_nvp<||> ~> Service<| title == 'neutron-server' |>
  Package['neutron-plugin-nvp'] -> Service<| title == 'neutron-server' |>

  package { 'neutron-plugin-nvp':
    ensure  => $package_ensure,
    name    => $::neutron::params::nvp_server_package
  }

  validate_array($nvp_controllers)

  neutron_plugin_nvp {
    'DEFAULT/default_tz_uuid': value => $default_tz_uuid;
    'DEFAULT/nvp_controllers': value => join($nvp_controllers, ',');
    'DEFAULT/nvp_user':        value => $nvp_user;
    'DEFAULT/nvp_password':    value => $nvp_password, secret => true;
    'nvp/metadata_mode':       value => 'access_network';
  }

  if($default_l3_gw_service_uuid) {
    neutron_plugin_nvp {
      'DEFAULT/default_l3_gw_service_uuid': value => $default_l3_gw_service_uuid;
    }
  }

  if $::neutron::core_plugin != 'neutron.plugins.nicira.NeutronPlugin.NvpPluginV2' {
    fail('nvp plugin should be the core_plugin in neutron.conf')
  }

  # In RH, this link is used to start Neutron process but in Debian, it's used only
  # to manage database synchronization.
  file {'/etc/neutron/plugin.ini':
    ensure  => link,
    target  => '/etc/neutron/plugins/nicira/nvp.ini',
    require => Package['neutron-plugin-nvp']
  }

}
