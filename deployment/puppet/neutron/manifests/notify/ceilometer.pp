class neutron::notify::ceilometer (
  $driver = "neutron.openstack.common.notifier.rpc_notifier",
)
{
  neutron_config {
    'DEFAULT/notification_driver': value => $driver;
  }
}
