# create dirs for devices
define openstack_tasks::swift::parts::device_directory($devices) {
  if (!defined(File[$devices])) {
    file { $devices:
      ensure       => 'directory',
      owner        => 'swift',
      group        => 'swift',
      recurse      => true,
      recurselimit => 1,
    }
  }
}