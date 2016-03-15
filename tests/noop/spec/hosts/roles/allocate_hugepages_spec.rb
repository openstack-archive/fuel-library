require 'spec_helper'
require 'shared-examples'
manifest = 'roles/allocate_hugepages.pp'

describe manifest do
  shared_examples 'catalog' do
    hugepages = Noop.hiera 'hugepages', []
    mapped_sysfs_hugepages = hugepages.empty? ? { 'default' => 0 } : {
      'node0/hugepages/hugepages-2048kB' => 512,
      'node1/hugepages/hugepages-1048576kB' => 8,
      'default' => 0
    }
    max_map_count = hugepages.empty? ? '65530' : '66570'

    it "should allocate defined hugepages" do
      should contain_class('sysfs')
      should contain_sysfs_config_value('hugepages').with(
        'ensure' => 'present',
        'name'   => '/etc/sysfs.d/hugepages.conf',
        'value'  => mapped_sysfs_hugepages,
        'sysfs'  => '/sys/devices/system/node/node*/hugepages/hugepages-*kB/nr_hugepages',
      )
      should contain_sysctl__value('vm.max_map_count').with_value(max_map_count)
    end
  end
  test_ubuntu_and_centos manifest
end
