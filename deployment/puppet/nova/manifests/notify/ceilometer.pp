class nova::notify::ceilometer(
  $instance_usage_audit        = true,
  $instance_usage_audit_period = 'hour',
  $notify_on_state_change      = 'vm_and_task_state',
  $notification_driver         = 'messaging',
)
{
  nova_config {
    'DEFAULT/instance_usage_audit':        value => $instance_usage_audit;
    'DEFAULT/instance_usage_audit_period': value => $instance_usage_audit_period;
    'DEFAULT/notify_on_state_change':      value => $notify_on_state_change;
    'DEFAULT/notification_driver':         value => $notification_driver;
  }
}
