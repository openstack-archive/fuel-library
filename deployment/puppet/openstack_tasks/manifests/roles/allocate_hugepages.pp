class openstack_tasks::roles::allocate_hugepages {

  notice('MODULAR: roles/allocate_hugepages.pp')

  $hugepages = hiera('hugepages', [])

  # TODO: (vvalyavskiy) currently, it was decided to not include 'hugepages' mapping data into
  # deployment info if 1GB hugepages is enabled. So, it means that no hugepages count should
  # be configured in runtime in this case.
  unless empty($hugepages) {
    include ::sysfs

    sysfs_config_value { 'hugepages':
      ensure => 'present',
      name   => '/etc/sysfs.d/hugepages.conf',
      value  => map_sysfs_hugepages($hugepages),
      sysfs  => '/sys/devices/system/node/node*/hugepages/hugepages-*kB/nr_hugepages',
    }

    # LP 1507921
    sysctl::value { 'vm.max_map_count':
      value  => max_map_count_hugepages($hugepages),
    }
  }
}
