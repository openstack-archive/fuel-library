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


    let(:params) { {
      containers => ['astute', 'cobbler', 'keystone', 'mcollective', 'nailgun',
    'nginx', 'ostf', 'postgres', 'rabbitmq', 'rsync', 'rsyslog']
    } }

    context 'running on centos 6' do
      let(:facts) do
        Noop.centos_facts.merge({
          :operatingsystemmajrelease => '6'
        })
      end
      it 'configure containers supervisor' do
        release = facts[:fuel_release]

        should contain_class('docker::supervisor').with({
          :release => release,
          :require => "File[/etc/supervisord.d/#{release}]",
        })
        params[:containers].each do |container|
          should contain_file("/etc/supervisord.d/#{release}/#{container}.conf").with({
            :owner => 'root',
            :group => 'root',
            :mode  => '0644'
          })
        end
      end #it do
    end #context

    context 'running on centos 7' do
      let(:facts) do
        Noop.centos_facts.merge({
          :operatingsystemmajrelease => '7'
        })
      end

      it 'configure containers systemd' do
        release = facts[:fuel_release]

        should contain_class('docker::systemd').with({
          :release => release
        })
        params[:containers].each do |container|
          should contain_file("/usr/lib/systemd/system/docker-#{container}.service").with({
            :owner => 'root',
            :group => 'root',
            :mode  => '0644',
          })
          should contain_service("docker-#{container}").with({
            :ensure => 'undef',
            :enable => 'true',
          })
        end
      end #it do
    end #context
  end #shared_examples

  test_centos manifest
end
