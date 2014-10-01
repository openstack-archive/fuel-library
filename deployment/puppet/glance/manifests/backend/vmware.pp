class glance::backend::vmware(
  $vcenter_host,
  $vcenter_user,
  $vcenter_password,
  $vcenter_datacenter,
  $vcenter_datastore,
  $vcenter_image_dir,
) {
  glance_api_config {
    'DEFAULT/default_store': value => 'vsphere';
    'DEFAULT/vmware_api_insecure': value => 'False';
    'DEFAULT/vmware_server_host': value => $vcenter_host;
    'DEFAULT/vmware_server_username': value => $vcenter_user;
    'DEFAULT/vmware_server_password': value => $vcenter_password;
    'DEFAULT/vmware_datastore_name': value => $vcenter_datastore;
    'DEFAULT/vmware_store_image_dir': value => $vcenter_image_dir;
    'DEFAULT/vmware_task_poll_interval': value => '5';
    'DEFAULT/vmware_api_retry_count': value => '10';
    'DEFAULT/vmware_datacenter_path': value => $vcenter_datacenter;
  }
}
