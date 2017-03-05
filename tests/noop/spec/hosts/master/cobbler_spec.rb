require 'spec_helper'
require 'shared-examples'
require 'yaml'
manifest = 'master/cobbler.pp'

# HIERA: master
# FACTS: master_centos7

describe manifest do
  shared_examples 'catalog' do
    let(:fuel_settings) do
      YAML.load facts[:astute_settings_yaml]
    end

    let(:bootstrap_settings) do
      fuel_settings.fetch 'BOOTSTRAP', {}
    end

    it 'should contain class "fuel::cobbler" with correct parameters' do
      parameters = {
          :cobbler_user                => fuel_settings['cobbler']['user'],
          :cobbler_password            => fuel_settings['cobbler']['password'],
          :bootstrap_path              => bootstrap_settings.fetch('path', '/var/www/nailgun/bootstraps/active_bootstrap'),
          # :bootstrap_meta              => nil,
          :server                      => fuel_settings['ADMIN_NETWORK']['ipaddress'],
          :name_server                 => fuel_settings['ADMIN_NETWORK']['ipaddress'],
          :next_server                 => fuel_settings['ADMIN_NETWORK']['ipaddress'],
          :mco_user                    => fuel_settings['mcollective']['user'],
          :mco_pass                    => fuel_settings['mcollective']['password'],
          :dns_upstream                => [fuel_settings['DNS_UPSTREAM']],
          :dns_domain                  => fuel_settings['DNS_DOMAIN'],
          :dns_search                  => fuel_settings['DNS_SEARCH'],
          :dhcp_ipaddress              => fuel_settings['ADMIN_NETWORK']['ipaddress'],
          :nailgun_api_url             => "http://#{fuel_settings['ADMIN_NETWORK']['ipaddress']}:8000/api",
          :bootstrap_ethdevice_timeout => bootstrap_settings.fetch('ethdevice_timeout', '120'),
      }
      is_expected.to contain_class('fuel::cobbler').with parameters
    end

    it { is_expected.to contain_file '/etc/resolv.conf' }

    %w(httpd cobblerd xinetd).each do |service|
      it "should containt '#{service}' fuel::systemd service with correct parameters" do
        parameters = {
            :start => true,
            :template_path => 'fuel/systemd/restart_template.erb',
            :config_name => 'restart.conf',
        }
        is_expected.to contain_fuel__systemd(service).with parameters
      end
    end

    it "should containt dnsmasq fuel::systemd service with correct parameters" do
        parameters = {
            :start => true,
            :template_path => 'fuel/systemd/dnsmasq_template.erb',
            :config_name => 'restart.conf',
        }
        is_expected.to contain_fuel__systemd(service).with parameters
    end

    it 'should declare the "fuel::dnsmasq::dhcp_range" with "default" title and correct parameters' do
      parameters = {
       :dhcp_start_address => fuel_settings['ADMIN_NETWORK']['dhcp_pool_start'],
       :dhcp_end_address   => fuel_settings['ADMIN_NETWORK']['dhcp_pool_end'],
       :dhcp_netmask       => fuel_settings['ADMIN_NETWORK']['netmask'],
       :dhcp_gateway       => fuel_settings['ADMIN_NETWORK']['dhcp_gateway'],
       :next_server        => fuel_settings['ADMIN_NETWORK']['ipaddress'],
       :listen_address     => fuel_settings['ADMIN_NETWORK']['ipaddress'],
      }
      is_expected.to contain_fuel__dnsmasq__dhcp_range('default').with parameters
      is_expected.to contain_fuel__dnsmasq__dhcp_range('default').that_notifies 'Service[dnsmasq]'
    end

    it { is_expected.to contain_cobbler_profile('ubuntu_bootstrap').with_kopts(/\bip=frommedia\b/) }

  end
  run_test manifest
end
