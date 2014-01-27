# == Class: neutron::quota
#
# Setups neutron quota.
#
# === Parameters
#
# [*default_quota*]
#   (optional) Default number of resources allowed per tenant,
#   minus for unlimited. Defaults to -1.
#
# [*quota_network*]
#   (optional) Number of networks allowed per tenant, and minus means unlimited.
#   Defaults to 10.
#
# [*quota_subnet*]
#   (optional) Number of subnets allowed per tenant, and minus means unlimited.
#   Defaults to 10.
#
# [*quota_port*]
#   (optional) Number of ports allowed per tenant, and minus means unlimited.
#   Defaults to 50.
#
# [*quota_router*]
#   (optional) Number of routers allowed per tenant, and minus means unlimited.
#   Requires L3 extension. Defaults to 10.
#
# [*quota_floatingip*]
#   (optional) Number of floating IPs allowed per tenant,
#   and minus means unlimited. Requires L3 extension. Defaults to 50.
#
# [*quota_security_group*]
#   (optional) Number of security groups allowed per tenant,
#   and minus means unlimited. Requires securitygroup extension.
#   Defaults to 10.
#
# [*quota_security_group_rule*]
#   (optional) Number of security rules allowed per tenant,
#   and minus means unlimited. Requires securitygroup extension.
#   Defaults to 100.
#
# [*quota_driver*]
#   (optional) Default driver to use for quota checks.
#   Defaults to 'neutron.db.quota_db.DbQuotaDriver'.
#
# [*quota_firewall*]
#   (optional) Number of firewalls allowed per tenant, -1 for unlimited.
#   Defaults to '1'.
#
# [*quota_firewall_policy*]
#   (optional) Number of firewalls policies allowed per tenant, -1 for unlimited.
#   Defaults to '1'.
#
# [*quota_firewall_rule*]
#   (optional) Number of firewalls rules allowed per tenant, -1 for unlimited.
#   Defaults to '-1'.
#
class neutron::quota (
  $default_quota             = -1,
  $quota_network             = 10,
  $quota_subnet              = 10,
  $quota_port                = 50,
  # l3 extension
  $quota_router              = 10,
  $quota_floatingip          = 50,
  # securitygroup extension
  $quota_security_group      = 10,
  $quota_security_group_rule = 100,
  $quota_driver              = 'neutron.db.quota_db.DbQuotaDriver',
  $quota_firewall            = 1,
  $quota_firewall_policy     = 1,
  $quota_firewall_rule       = -1
) {

  neutron_config {
    'QUOTAS/default_quota':             value => $default_quota;
    'QUOTAS/quota_network':             value => $quota_network;
    'QUOTAS/quota_subnet':              value => $quota_subnet;
    'QUOTAS/quota_port':                value => $quota_port;
    'QUOTAS/quota_router':              value => $quota_router;
    'QUOTAS/quota_floatingip':          value => $quota_floatingip;
    'QUOTAS/quota_security_group':      value => $quota_security_group;
    'QUOTAS/quota_security_group_rule': value => $quota_security_group_rule;
    'QUOTAS/quota_driver':              value => $quota_driver;
    'QUOTAS/quota_firewall':            value => $quota_firewall;
    'QUOTAS/quota_firewall_policy':     value => $quota_firewall_policy;
    'QUOTAS/quota_firewall_rule':       value => $quota_firewall_rule;
  }
}
