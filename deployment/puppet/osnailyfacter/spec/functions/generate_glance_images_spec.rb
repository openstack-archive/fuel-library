require 'spec_helper'

describe 'generate_glance_images' do

  let(:input) {
    [
      {
        'container_format'  => 'bare',
        'disk_format'       => 'vmdk',
        'glance_properties' => '--property hypervisor_type=vmware --property vmware_disktype=sparse --property vmware_adaptertype=lsiLogic',
        'img_name'          => 'TestVM-VMDK',
        'img_path'          => '/usr/share/cirros-testvm/cirros-i386-disk.vmdk',
        'min_ram'           => '64',
        'os_name'           => 'cirros',
        'properties'        => {
          'hypervisor_type'    => 'vmware',
          'vmware_adaptertype' => 'lsiLogic',
          'vmware_disktype'    => 'sparse',
        },
        'public'            => 'true',
      },
      {
        'container_format'  => 'bare',
        'disk_format'       => 'qcow2',
        'glance_properties' => '',
        'img_name'          => 'TestVM',
        'img_path'          => '/usr/share/cirros-testvm/cirros-x86_64-disk.img',
        'min_ram'           => '64',
        'os_name'           => 'cirros',
        'properties'        => {},
        'public'            => 'true',
      },
    ]
  }

  let (:output) {
    {
      'TestVM-VMDK' => {
        'container_format' => 'bare',
        'disk_format'      => 'vmdk',
        'is_public'        => 'true',
        'min_ram'          => '64',
        'source'           => '/usr/share/cirros-testvm/cirros-i386-disk.vmdk',
        'properties'       => {
          'hypervisor_type'    => 'vmware',
          'vmware_adaptertype' => 'lsiLogic',
          'vmware_disktype'    => 'sparse',
        },
      },
      'TestVM' => {
        'container_format' => 'bare',
        'disk_format'      => 'qcow2',
        'is_public'        => 'true',
        'min_ram'          => '64',
        'source'           => '/usr/share/cirros-testvm/cirros-x86_64-disk.img',
        'properties'       => {},
      },
    }
  }

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should expect 1 argument' do
    is_expected.to run.with_params().and_raise_error ArgumentError
  end

  it 'should expect array as given argument' do
    is_expected.to run.with_params('foobar').and_raise_error Puppet::ParseError
  end

  it 'should return glance compatible hash' do
    is_expected.to run.with_params(input).and_return(output)
  end
end
