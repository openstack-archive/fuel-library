class cinder::notify::ceilometer (
  $driver = 'cinder.openstack.common.notifier.rpc_notifier',
) inherits cinder::api {

  if $::cinder::api::enabled {
    cinder_config {
      'DEFAULT/notification_driver': value => $driver;
    }
  }
}
