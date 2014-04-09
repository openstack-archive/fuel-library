# == Class: nova::network::neutron
#
# Configures Nova network to use Neutron.
#
# === Parameters

# [*neutron_config*]
#   (required) Quantum config hash. Should includes all of the following options.
#
# [*neutron_admin_password*]
#   (required) Password for connecting to Neutron network services in
#   admin context through the OpenStack Identity service.
#
# [*neutron_auth_strategy*]
#   (optional) Should be kept as default 'keystone' for all production deployments.
#
# [*neutron_url*]
#   (optional) URL for connecting to the Neutron networking service.
#   Defaults to 'http://127.0.0.1:9696'.
#
# [*neutron_url_timeout*]
#   (optional) Timeout value for connecting to neutron in seconds.
#   Defaults to '30'.
#
# [*neutron_admin_tenant_name*]
#   (optional) Tenant name for connecting to Neutron network services in
#   admin context through the OpenStack Identity service. Defaults to 'services'.
#
# [*neutron_default_tenant_id*]
#   (optional) Default tenant id when creating neutron networks
#   Defaults to 'default'
#
# [*neutron_region_name*]
#   (optional) Region name for connecting to neutron in admin context
#   through the OpenStack Identity service. Defaults to 'RegionOne'.
#
# [*neutron_admin_username*]
#   (optional) Username for connecting to Neutron network services in admin context
#   through the OpenStack Identity service. Defaults to 'neutron'.
#
# [*neutron_ovs_bridge*]
#   (optional) Name of Integration Bridge used by Open vSwitch
#   Defaults to 'br-int'.
#
# [*neutron_extension_sync_interval*]
#   (optional) Number of seconds before querying neutron for extensions
#   Defaults to '600'.
#
# [*neutron_ca_certificates_file*]
#   (optional) Location of ca certicates file to use for neutronclient requests.
#   Defaults to 'None'.
#
# [*neutron_admin_auth_url*]
#   (optional) Points to the OpenStack Identity server IP and port.
#   This is the Identity (keystone) admin API server IP and port value,
#   and not the Identity service API IP and port.
#   Defaults to 'http://127.0.0.1:35357/v2.0'
#
# [*security_group_api*]
#   (optional) The full class name of the security API class.
#   Defaults to 'neutron' which configures Nova to use Neutron for
#   security groups. Set to 'nova' to use standard Nova security groups.
#
# [*firewall_driver*]
#   (optional) Firewall driver.
#   Defaults to nova.virt.firewall.NoopFirewallDriver. This prevents Nova
#   from maintaining a firewall so it does not interfere with Neutron's.
#   Set to 'nova.virt.firewall.IptablesFirewallDriver'
#   to re-enable the Nova firewall.
#
class nova::network::neutron (
  $neutron_config                  = {},
  $neutron_connection_host,
  $neutron_admin_password,
  $neutron_auth_strategy           = 'keystone',
  #TODO(bogdando) move options under the config hash and use it
  $neutron_url_timeout             = '30',
  $neutron_admin_tenant_name       = 'services',
  $neutron_default_tenant_id       = 'default',
  $neutron_region_name             = 'RegionOne',
  $neutron_admin_username          = 'neutron',
  $neutron_ovs_bridge              = 'br-int',
  $neutron_extension_sync_interval = '600',
  $neutron_ca_certificates_file    = undef,
  $security_group_api              = 'neutron',
  $firewall_driver                 = 'nova.virt.firewall.NoopFirewallDriver'
) {

  if $neutron_connection_host != 'localhost' {
    nova_config { 'DEFAULT/neutron_connection_host': value => $neutron_connection_host }
  }

  nova_config {
    'DEFAULT/network_api_class':         value => 'nova.network.neutronv2.api.API';  # neutronv2 !!! not a neutron.v2
    'DEFAULT/neutron_auth_strategy':     value => $neutron_auth_strategy;
    'DEFAULT/neutron_url':               value => $neutron_config['server']['api_url'];
    'DEFAULT/neutron_url_timeout':       value => $neutron_url_timeout;
    'DEFAULT/neutron_admin_tenant_name': value => $neutron_config['keystone']['admin_tenant_name'];
    'DEFAULT/neutron_admin_username':    value => $neutron_config['keystone']['admin_user'];
    'DEFAULT/neutron_admin_password':    value => $neutron_config['keystone']['admin_password'];
    'DEFAULT/neutron_admin_auth_url':    value => $neutron_config['keystone']['auth_url'];
    'DEFAULT/firewall_driver':           value => $firewall_driver;
    'DEFAULT/security_group_api':        value => 'neutron';
  }

  if ! $neutron_ca_certificates_file {
    nova_config { 'DEFAULT/neutron_ca_certificates_file': ensure => absent }
  } else {
    nova_config { 'DEFAULT/neutron_ca_certificates_file': value => $neutron_ca_certificates_file }
  }

}
