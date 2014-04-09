class heat::notify::ceilometer (
  $driver = 'heat.openstack.common.notifier.rpc_notifier',
) {

  heat_config {
    'DEFAULT/notification_driver': value => $driver;
  }
}
