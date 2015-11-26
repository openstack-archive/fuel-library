require 'spec_helper'
require 'shared-examples'
require 'yaml'
manifest = 'master/host-only.pp'

describe manifest do
  shared_examples 'catalog' do

    bootstrap_hash = {
      'MIRROR_DISTRO'   => "http://archive.ubuntu.com/ubuntu",
      'MIRROR_MOS'      => "http://mirror.fuel-infra.org/mos-repos/ubuntu/8.0",
      'HTTP_PROXY'      => "",
      'EXTRA_APT_REPOS' => "",
      'flavor'          => "centos"
    }

    it 'should declare nailgun::bootstrap_cli class with proper arguments' do
      should contain_class('nailgun::bootstrap_cli').with(
        'settings'              => bootstrap_hash,
        'direct_repo_addresses' => ['10.109.0.2'],
        'bootstrap_cli_package' => 'fuel-bootstrap-cli',
        'config_path'           => '/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml',
      )
    end

    it "should install fuel-bootstrap-cli package" do
      should contain_package('fuel-bootstrap-cli').with(
        'ensure' => 'present',
      )
    end

    bootstrap_hash['direct_repo_addresses'] = ['10.109.0.2']

    it 'should contain generated config file for cli bootstrap util' do
      should contain_file('/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml').with(
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
        'require' => 'Package[fuel-bootstrap-cli]').with_content(
          "\n#{bootstrap_hash.to_yaml.to_s}\n")
    end

  end
  test_centos manifest
end
