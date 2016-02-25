require 'spec_helper'
require 'shared-examples'
require 'yaml'
manifest = 'master/nginx_services.pp'

# HIERA: master
# FACTS: master_centos7 master_centos6

describe manifest do
  shared_examples 'catalog' do
    let(:fuel_settings) do
      YAML.load facts[:astute_settings_yaml]
    end

    let(:service_enabled) do
      !! (facts[:operatingsystemrelease] =~ /^7.*/)
    end

    it 'should declare "fuel::nginx::services" class correctly' do
      parameters = {
        :ostf_host       => fuel_settings['ADMIN_NETWORK']['ipaddress'],
        :keystone_host   => fuel_settings['ADMIN_NETWORK']['ipaddress'],
        :nailgun_host    => fuel_settings['ADMIN_NETWORK']['ipaddress'],
        :service_enabled => service_enabled,
        :ssl_enabled     => true,
        :force_https     => fuel_settings.fetch('SSL', {}).fetch('force_https', nil),
      }
      is_expected.to contain_class('fuel::nginx::services').with parameters
    end
  end

  run_test manifest
end

