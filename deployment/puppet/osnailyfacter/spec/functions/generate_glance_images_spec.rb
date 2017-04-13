require 'spec_helper'

describe 'generate_glance_images' do

  let (:image_opts) {
    {
      'container_format' => 'bare',
      'disk_format'      => 'qcow2',
      'min_ram'          => '64',
      'properties'       => {},
    }
  }

  let(:input) {
    [
      {
        'glance_properties' => '',
        'img_name'          => 'TestVM',
        'img_path'          => '/usr/share/cirros-testvm/cirros-x86_64-disk.img',
        'os_name'           => 'cirros',
        'public'            => 'true',
      }.merge(image_opts),
    ]
  }

  let (:output) {
    {
      'TestVM' => {
        'is_public' => 'true',
        'source'    => '/usr/share/cirros-testvm/cirros-x86_64-disk.img',
      }.merge(image_opts),
    }
  }

  let (:extra_properties) {
    {
      'hw_scsi_model' => 'virtio-scsi',
      'hw_disk_bus'   => 'scsi',
    }
  }

  let (:output_with_extra) {
    {
      'TestVM' => {
        'is_public' => 'true',
        'source'    => '/usr/share/cirros-testvm/cirros-x86_64-disk.img',
      }.merge(image_opts).merge('properties' => image_opts['properties'].merge(extra_properties)),
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
    is_expected.to run.with_params(input, extra_properties).and_return(output_with_extra)
  end
end
