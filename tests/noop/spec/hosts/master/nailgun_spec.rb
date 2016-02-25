require 'spec_helper'
require 'shared-examples'
require 'yaml'
manifest = 'master/nailgun.pp'

# HIERA: master
# FACTS: master_centos7

describe manifest do
  before(:each) do
    Noop.puppet_function_load :file
    MockFunction.new(:file) do |function|
      allow(function).to receive(:call).with(['/root/.ssh/id_rsa.pub']).and_return('key')
    end
  end

  shared_examples 'catalog' do
    let(:fuel_settings) do
      YAML.load facts[:astute_settings_yaml]
    end

    it 'should declare "fuel::nailgun::server" class correctly' do
      parameters = {
          :keystone_host            => fuel_settings['ADMIN_NETWORK']['ipaddress'],
          :keystone_user            => fuel_settings['keystone']['nailgun_user'],
          :keystone_password        => fuel_settings['keystone']['nailgun_password'],
          :feature_groups           => fuel_settings['FEATURE_GROUPS'] || [],
          :nailgun_log_level        => fuel_settings['DEBUG'] ? 'DEBUG' : 'INFO',
          :db_name                  => fuel_settings['postgres']['nailgun_dbname'],
          :db_host                  => fuel_settings['ADMIN_NETWORK']['ipaddress'],
          :db_user                  => fuel_settings['postgres']['nailgun_user'],
          :db_password              => fuel_settings['postgres']['nailgun_password'],
          :rabbitmq_host            => fuel_settings['ADMIN_NETWORK']['ipaddress'],
          :rabbitmq_astute_user     => fuel_settings['astute']['user'],
          :rabbitmq_astute_password => fuel_settings['astute']['password'],

          :admin_network            => Noop.puppet_function(
              'ipcalc_network_by_address_netmask',
              fuel_settings['ADMIN_NETWORK']['ipaddress'],
              fuel_settings['ADMIN_NETWORK']['netmask']
          ),
          :admin_network_cidr       => Noop.puppet_function(
              'ipcalc_network_cidr_by_netmask',
              fuel_settings['ADMIN_NETWORK']['netmask']
          ),
          :admin_network_size       => Noop.puppet_function(
              'ipcalc_network_count_addresses',
              fuel_settings['ADMIN_NETWORK']['ipaddress'],
              fuel_settings['ADMIN_NETWORK']['netmask']
          ),

          :admin_network_first      => fuel_settings['ADMIN_NETWORK']['dhcp_pool_start'],
          :admin_network_last       => fuel_settings['ADMIN_NETWORK']['dhcp_pool_end'],
          :admin_network_netmask    => fuel_settings['ADMIN_NETWORK']['netmask'],
          :admin_network_mac        => fuel_settings['ADMIN_NETWORK']['mac'],
          :admin_network_ip         => fuel_settings['ADMIN_NETWORK']['ipaddress'],
          :admin_network_gateway    => fuel_settings['ADMIN_NETWORK']['dhcp_gateway'],
          :cobbler_host             => fuel_settings['ADMIN_NETWORK']['ipaddress'],
          :cobbler_url              => "http://#{fuel_settings['ADMIN_NETWORK']['ipaddress']}:80/cobbler_api",
          :cobbler_user             => fuel_settings['cobbler']['user'],
          :cobbler_password         => fuel_settings['cobbler']['password'],
          :mco_host                 => fuel_settings['ADMIN_NETWORK']['ipaddress'],
          :mco_user                 => fuel_settings['mcollective']['user'],
          :mco_password             => fuel_settings['mcollective']['password'],
          :ntp_upstream             => [fuel_settings['NTP1'], fuel_settings['NTP2'], fuel_settings['NTP3'], ''].reject {|v| v.to_s.empty? },
          :dns_upstream             => fuel_settings.fetch('DNS_UPSTREAM', '').split.map {|s| s.strip },
          :dns_domain               => fuel_settings['DNS_DOMAIN'],
      }
      is_expected.to contain_class('fuel::nailgun::server').with parameters
    end
  end

  run_test manifest
end
