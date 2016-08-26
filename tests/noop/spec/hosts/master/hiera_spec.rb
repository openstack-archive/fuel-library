require 'spec_helper'
require 'shared-examples'
manifest = 'master/hiera.pp'

# HIERA: master
# FACTS: master_centos7 master_centos6

describe manifest do
  shared_examples 'catalog' do
    it do
      is_expected.to contain_file('hiera_data_dir').with(
          'ensure' => 'directory',
          'path' => '/etc/hiera',
          'mode' => '0750',

      )
    end

    it do
      is_expected.to contain_hiera_config('master_hiera_yaml').with(
          'ensure' => 'present',
          'path' => '/etc/hiera.yaml',
      )
    end

    it do
      is_expected.to contain_file('hiera_data_astute').with(
          'ensure' => 'symlink',
          'path' => '/etc/hiera/astute.yaml',
          'target' => '/etc/fuel/astute.yaml'
      )
    end

    it do
      is_expected.to contain_file('hiera_puppet_config').with(
          'ensure' => 'symlink',
          'path' => '/etc/puppet/hiera.yaml',
          'target' => '/etc/hiera.yaml'
      )
    end
  end

  run_test manifest
end
