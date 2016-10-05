# create dirs for devices
define openstack_tasks::swift::parts::device_directory($devices) {
  if (!defined(File[$devices])) {
    file { $devices:
      ensure       => 'directory',
      owner        => 'glance',
      group        => 'glance',
      mode         => '0775',
      recurse      => true,
      recurselimit => 1,
    }
  }
}
