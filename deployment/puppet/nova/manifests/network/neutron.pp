# == Class: nova::network::neutron
#
# Configures Nova network to use Neutron.
#
# === Parameters:
#
# [*neutron_admin_password*]
#   (required) Password for connecting to Neutron network services in
#   admin context through the OpenStack Identity service.
#
# [*neutron_auth_strategy*]
#   (optional) Should be kept as default 'keystone' for all production deployments.
#   Defaults to 'keystone'
#
# [*neutron_url*]
#   (optional) URL for connecting to the Neutron networking service.
#   Defaults to 'http://127.0.0.1:9696'
#
# [*neutron_url_timeout*]
#   (optional) Timeout value for connecting to neutron in seconds.
#   Defaults to '30'
#
# [*neutron_admin_tenant_name*]
#   (optional) Tenant name for connecting to Neutron network services in
#   admin context through the OpenStack Identity service.
#   Defaults to 'services'
#
# [*neutron_default_tenant_id*]
#   (optional) Default tenant id when creating neutron networks
#   Defaults to 'default'
#
# [*neutron_region_name*]
#   (optional) Region name for connecting to neutron in admin context
#   through the OpenStack Identity service.
#   Defaults to 'RegionOne'
#
# [*neutron_admin_username*]
#   (optional) Username for connecting to Neutron network services in admin context
#   through the OpenStack Identity service.
#   Defaults to 'neutron'
#
# [*neutron_ovs_bridge*]
#   (optional) Name of Integration Bridge used by Open vSwitch
#   Defaults to 'br-int'
#
# [*neutron_extension_sync_interval*]
#   (optional) Number of seconds before querying neutron for extensions
#   Defaults to '600'
#
# [*neutron_ca_certificates_file*]
#   (optional) Location of ca certicates file to use for neutronclient requests.
#   Defaults to 'None'
#
# [*neutron_admin_auth_url*]
#   (optional) Points to the OpenStack Identity server IP and port.
#   This is the Identity (keystone) admin API server IP and port value,
#   and not the Identity service API IP and port.
#   Defaults to 'http://127.0.0.1:35357/v2.0'
#
# [*network_api_class*]
#   (optional) The full class name of the network API class.
#   The default configures Nova to use Neutron for the network API.
#   Defaults to 'nova.network.neutronv2.api.API'
#
# [*security_group_api*]
#   (optional) The full class name of the security API class.
#   The default configures Nova to use Neutron for security groups.
#   Set to 'nova' to use standard Nova security groups.
#   Defaults to 'neutron'
#
# [*firewall_driver*]
#   (optional) Firewall driver.
#   This prevents nova from maintaining a firewall so it does not interfere
#   with Neutron's. Set to 'nova.virt.firewall.IptablesFirewallDriver'
#   to re-enable the Nova firewall.
#   Defaults to 'nova.virt.firewall.NoopFirewallDriver'
#
# [*vif_plugging_is_fatal*]
#   (optional) Fail to boot instance if vif plugging fails.
#   This prevents nova from booting an instance if vif plugging notification
#   is not received from neutron.
#   Defaults to 'True'
#
# [*vif_plugging_timeout*]
#   (optional) Number of seconds to wait for neutron vif plugging events.
#   Set to '0' and vif_plugging_is_fatal to 'False' if vif plugging
#   notification is not being used.
#   Defaults to '300'
#
# [*dhcp_domain*]
#   (optional) domain to use for building the hostnames
#   Defaults to 'novalocal'
#
class nova::network::neutron (
  $neutron_admin_password,
  $neutron_auth_strategy           = 'keystone',
  $neutron_url                     = 'http://127.0.0.1:9696',
  $neutron_url_timeout             = '30',
  $neutron_admin_tenant_name       = 'services',
  $neutron_default_tenant_id       = 'default',
  $neutron_region_name             = 'RegionOne',
  $neutron_admin_username          = 'neutron',
  $neutron_admin_auth_url          = 'http://127.0.0.1:35357/v2.0',
  $neutron_ovs_bridge              = 'br-int',
  $neutron_extension_sync_interval = '600',
  $neutron_ca_certificates_file    = undef,
  $network_api_class               = 'nova.network.neutronv2.api.API',
  $security_group_api              = 'neutron',
  $firewall_driver                 = 'nova.virt.firewall.NoopFirewallDriver',
  $vif_plugging_is_fatal           = true,
  $vif_plugging_timeout            = '300',
  $dhcp_domain                     = 'novalocal',
) {

  nova_config {
    'DEFAULT/dhcp_domain':             value => $dhcp_domain;
    'DEFAULT/firewall_driver':         value => $firewall_driver;
    'DEFAULT/network_api_class':       value => $network_api_class;
    'DEFAULT/security_group_api':      value => $security_group_api;
    'DEFAULT/vif_plugging_is_fatal':   value => $vif_plugging_is_fatal;
    'DEFAULT/vif_plugging_timeout':    value => $vif_plugging_timeout;
    'neutron/auth_strategy':           value => $neutron_auth_strategy;
    'neutron/url':                     value => $neutron_url;
    'neutron/url_timeout':             value => $neutron_url_timeout;
    'neutron/admin_tenant_name':       value => $neutron_admin_tenant_name;
    'neutron/default_tenant_id':       value => $neutron_default_tenant_id;
    'neutron/region_name':             value => $neutron_region_name;
    'neutron/admin_username':          value => $neutron_admin_username;
    'neutron/admin_password':          value => $neutron_admin_password, secret => true;
    'neutron/admin_auth_url':          value => $neutron_admin_auth_url;
    'neutron/ovs_bridge':              value => $neutron_ovs_bridge;
    'neutron/extension_sync_interval': value => $neutron_extension_sync_interval;
  }

  if ! $neutron_ca_certificates_file {
    nova_config { 'neutron/ca_certificates_file': ensure => absent }
  } else {
    nova_config { 'neutron/ca_certificates_file': value => $neutron_ca_certificates_file }
  }

}
