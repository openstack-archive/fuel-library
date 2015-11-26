require 'spec_helper'
require 'shared-examples'
manifest = 'hiera/override_config.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should setup hiera' do
      should contain_file('hiera_override_dir').with(
        'ensure' => 'directory',
        'path'   => '/etc/hiera/override'
      )
      should contain_file('hiera_override_config_dir').with(
        'ensure' => 'directory',
        'path'   => '/etc/hiera/override/config'
      )
    end
  end

  test_ubuntu_and_centos manifest
end

