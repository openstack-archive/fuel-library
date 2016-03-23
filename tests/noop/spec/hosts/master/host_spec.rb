require 'spec_helper'
require 'shared-examples'
require 'yaml'
manifest = 'master/host.pp'

# HIERA: master
# FACTS: master_centos7

describe manifest do
  shared_examples 'catalog' do
    let(:fuel_settings) do
      YAML.load facts[:astute_settings_yaml]
    end

    %w(
      /root/.ssh/config
      /var/log/remote
      /var/www/nailgun/dump
      /etc/dhcp/dhcp-enter-hooks
      /etc/resolv.conf
      /etc/dhcp/dhclient.conf
      /etc/fuel/free_disk_check.yaml
      /etc/fuel-utils/config
      /var/lib/fuel
      /var/lib/fuel/ibp
      /var/lib/hiera
      /etc/puppet/hiera.yaml
      /var/lib/hiera/common.yaml
    ).each do |file|
      it { is_expected.to contain_file file }
    end

    it 'should have fuel::sshkeygen' do
      is_expected.to contain_fuel__sshkeygen '/root/.ssh/id_rsa'
    end

    [
        ['kernel.printk', '4 1 1 7'],
        ['net.ipv4.neigh.default.gc_thresh1', '256'],
        ['net.ipv4.neigh.default.gc_thresh2', '1024'],
        ['net.ipv4.neigh.default.gc_thresh3', '2048'],
    ].each do |key, value|
      it { is_expected.to contain_sysctl__value(key).with(:value => value) }
    end

    it 'should reserve unprivleged ports for services' do
      is_expected.to contain_class '::openstack::reserved_ports' with {
          :ports => '15672,25151,35357,41055,61613',
      }
    end

    it { is_expected.to contain_class 'monit' }

    it { is_expected.to contain_exec 'Change protocol and port in in issue' }

    it { is_expected.to contain_service('dhcrelay').with(:ensure => 'stopped')}

    it 'will contain "acpid" class only on a physical system' do
      is_expected.not_to contain_class 'acpid'
    end

    it { is_expected.to contain_class 'osnailyfacter::atop' }

    it 'should declare "osnailyfacter::ssh" class with correct parameters' do
      parameters = {
          :password_auth  => 'yes',
          :listen_address => ['0.0.0.0'],
      }
      is_expected.to contain_class('osnailyfacter::ssh').with parameters
    end

    it 'should declare "fuel::iptables" class with correct parameters' do
      parameters = {
        :admin_iface => fuel_settings['ADMIN_NETWORK']['interface'],
        :ssh_network => fuel_settings['ADMIN_NETWORK']['ssh_network'],
        :network_address => Noop.puppet_function(
            'ipcalc_network_by_address_netmask',
            fuel_settings['ADMIN_NETWORK']['ipaddress'],
            fuel_settings['ADMIN_NETWORK']['netmask'],
        ),
        :network_cidr => Noop.puppet_function(
            'ipcalc_network_cidr_by_netmask',
            fuel_settings['ADMIN_NETWORK']['netmask'],
        ),
      }
      is_expected.to contain_class('fuel::iptables').with parameters
    end

    it 'should declare "openstack::clocksync" class with parameters' do
      parameters = {
          :ntp_servers     => [fuel_settings['NTP1'], fuel_settings['NTP2'], fuel_settings['NTP3'], ''].reject {|v| v.to_s.empty? },
          :config_template => 'ntp/ntp.conf.erb',
      }
      is_expected.to contain_class('openstack::clocksync').with parameters
    end

    it 'should declare "openstack::logrotate" class with parameters' do
      parameters = {
        :role     => 'server',
        :rotation => 'weekly',
        :keep     => '4',
        :minsize  => '10M',
        :maxsize  => '100M',
      }
      is_expected.to contain_class('openstack::logrotate').with parameters
    end

    it 'should declare "fuel::auxiliaryrepos" class with parameters' do
      parameters = {
          :fuel_version => facts[:fuel_release],
          :repo_root    => "/var/www/nailgun/#{facts[:fuel_openstack_version]}",
      }
      is_expected.to contain_class('fuel::auxiliaryrepos').with parameters
    end

    it 'should declare fuel::bootstrap_cli class with proper arguments' do
      parameters = {
          :settings => fuel_settings['BOOTSTRAP'],
          :direct_repo_addresses => [ fuel_settings['ADMIN_NETWORK']['ipaddress'], '127.0.0.1' ],
          :bootstrap_cli_package => 'fuel-bootstrap-cli',
          :config_path => '/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml',
      }
      is_expected.to contain_class('fuel::bootstrap_cli').with parameters
    end

    [
        'Remove ssh_config SendEnv defaults',
        'Password aging and length settings',
        'Password complexity',
        'Enable only SSHv2 connections from the master node',
        'Turn off sudo requiretty',
    ].each do |augeas|
      it { is_expected.to contain_augeas augeas }
    end

    it { is_expected.to contain_exec 'create-loop-devices' }

  end
  run_test manifest
end
