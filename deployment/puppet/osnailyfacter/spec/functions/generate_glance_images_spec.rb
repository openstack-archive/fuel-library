require 'spec_helper'

describe 'generate_glance_images' do

  let(:input) {
    [
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

  let (:extra_opts) {
    {
      'properties' => {
        'hw_scsi_model' => 'virtio-scsi',
        'hw_disk_bus'   => 'scsi',
      }
    }
  }

  let (:output) {
    {
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

  let (:output_with_extra) {
    {
      'TestVM' => output.values.merge(extra_opts)
    }
  }


  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should expect at least 1 argument' do
    is_expected.to run.with_params().and_raise_error ArgumentError
  end

  it 'should expect array as given argument' do
    is_expected.to run.with_params('foobar').and_raise_error Puppet::ParseError
  end

  it 'should return glance compatible hash' do
    is_expected.to run.with_params(input).and_return(output)
  end

  it 'should return glance compatible hash with extra options' do
    is_expected.to run.with_params(input, extra_opts).and_return(output_with_extra)
  end
end
