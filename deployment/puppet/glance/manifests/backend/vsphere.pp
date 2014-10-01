#
# configures the storage backend for glance
# as a vCenter/ESXi
#
#  $vcenter_api_insecure - Optional. Default: 'False'
#
#  $vcenter_host - Required.
#
#  $vcenter_user - Required.
#
#  $vcenter_password - Required.
#
#  $vcenter_datacenter - Required.
#
#  $vcenter_datastore - Required.
#
#  $vcenter_image_dir - Required.
#
#  $vcenter_task_poll_interval - Optional. Default: '5'
#
#  $vcenter_api_retry_count - Optional. Default: '10'
class glance::backend::vsphere(
  $vcenter_api_insecure = 'False',
  $vcenter_host,
  $vcenter_user,
  $vcenter_password,
  $vcenter_datacenter,
  $vcenter_datastore,
  $vcenter_image_dir,
  $vcenter_task_poll_interval = '5',
  $vcenter_api_retry_count = '10',
) {
  glance_api_config {
    'DEFAULT/default_store': value             => 'vsphere';
    'DEFAULT/vmware_api_insecure': value       => $vcenter_api_insecure;
    'DEFAULT/vmware_server_host': value        => $vcenter_host;
    'DEFAULT/vmware_server_username': value    => $vcenter_user;
    'DEFAULT/vmware_server_password': value    => $vcenter_password;
    'DEFAULT/vmware_datastore_name': value     => $vcenter_datastore;
    'DEFAULT/vmware_store_image_dir': value    => $vcenter_image_dir;
    'DEFAULT/vmware_task_poll_interval': value => $vcenter_task_poll_interval;
    'DEFAULT/vmware_api_retry_count': value    => $vcenter_api_retry_count;
    'DEFAULT/vmware_datacenter_path': value    => $vcenter_datacenter;
  }
}
