require 'spec_helper'
require 'shared-examples'
require 'yaml'
manifest = 'master/host-only.pp'

describe manifest do
  shared_examples 'catalog' do

    config_path = '/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml'
    bootstrap_cli_package = 'fuel-bootstrap-cli'

    bootstrap_hash = {
      'MIRROR_DISTRO'   => "http://archive.ubuntu.com/ubuntu",
      'MIRROR_MOS'      => "http://mirror.fuel-infra.org/mos-repos/ubuntu/8.0",
      'HTTP_PROXY'      => "",
      'EXTRA_APT_REPOS' => "",
      'flavor'          => "centos"
    }

    additional_settings_hash =  {
      'direct_repo_addresses' => ['10.109.0.2']
    }

    it 'should declare nailgun::bootstrap_cli class with proper arguments' do
      should contain_class('nailgun::bootstrap_cli').with(
        'settings'              => bootstrap_hash,
        'direct_repo_addresses' => additional_settings_hash['direct_repo_addresses'],
        'bootstrap_cli_package' => bootstrap_cli_package,
        'config_path'           => config_path,
      )
    end

    it "should install fuel-bootstrap-cli package" do
      should contain_package(bootstrap_cli_package).with(
        'ensure' => 'present',
      )
    end

    custom_settings = bootstrap_hash.merge(additional_settings_hash)

    it 'should declare merge_yaml_settings' do
      should contain_merge_yaml_settings(config_path).with({
        'sample_settings'   => config_path,
        'override_settings' => custom_settings,
        'ensure'            => 'present',
        'require'           => "Package[#{bootstrap_cli_package}]",
      })
    end

  end
  test_centos manifest
end
