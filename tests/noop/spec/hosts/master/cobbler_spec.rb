require 'spec_helper'
require 'shared-examples'
require 'yaml'
manifest = 'master/cobbler.pp'

# HIERA: master
# FACTS: master_centos7

describe manifest do

  before(:each) do
    Noop.puppet_function_load :loadmetadata
    MockFunction.new(:loadmetadata) do |function|
      allow(function).to receive(:call).and_return({})
    end
  end

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
          :dns_upstream                => fuel_settings['DNS_UPSTREAM'],
          :dns_domain                  => fuel_settings['DNS_DOMAIN'],
          :dns_search                  => fuel_settings['DNS_SEARCH'],
          :dhcp_interface              => fuel_settings['ADMIN_NETWORK']['interface'],
          :nailgun_api_url             => "http://#{fuel_settings['ADMIN_NETWORK']['ipaddress']}:8000/api",
          :bootstrap_ethdevice_timeout => bootstrap_settings.fetch('ethdevice_timeout', '120'),
      }
      is_expected.to contain_class('fuel::cobbler').with parameters
    end

    %w(httpd cobblerd dnsmasq xinetd).each do |service|
      it "should containt '#{service}' fuel::systemd service with correct parameters" do
        parameters = {
            :start => true,
            :template_path => 'fuel/systemd/restart_template.erb',
            :config_name => 'restart.conf',
        }
        is_expected.to contain_fuel__systemd(service).with parameters
      end
    end

    it 'should declare the "fuel::dnsmasq::dhcp_range" with "default" title and correct parameters' do
      parameters = {}
      is_expected.to contain_fuel__dnsmasq__dhcp_range('default').with parameters
    end

    it { is_expected.to contain_cobbler_profile('ubuntu_bootstrap').with_kopts(/\bip=frommedia\b/) }

  end
  run_test manifest
end
