notice('MODULAR: allocate_hugepages.pp')

$hugepages = hiera('hugepages', false)

if $hugepages {
  include sysfs

  sysfs_config_value { 'hugepages':
    ensure => 'present',
    name   => '/etc/sysfs.d/hugepages.conf',
    value  => map_sysfs_hugepages($hugepages),
    sysfs  => '/sys/devices/system/node/node*/hugepages/hugepages-*kB/nr_hugepages',
  }
}
