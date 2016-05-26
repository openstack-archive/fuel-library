# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'api-proxy/api-proxy.pp'

describe manifest do

  shared_examples 'catalog' do
    let(:master_ip) do
      Noop.hiera('master_ip')
    end

    let(:max_header_size) do
      Noop.hiera('max_header_size', '81900')
    end

    let(:ports) do
      Noop.hiera('apache_api_proxy_ports', ['443', '563', '5000', '6385', '8000', '8003', '8004', '8042', '8080', '8082', '8386', '8773', '8774', '8776', '8777', '9292', '9696'])
    end

    it {
      should contain_service('httpd').with(
           'hasrestart' => true,
           'restart'    => 'sleep 30 && apachectl graceful || apachectl restart'
      )
    }

    it 'should delcare osnailyfacter::apache_api_proxy' do
      expect(subject).to contain_class('osnailyfacter::apache_api_proxy').with(
        'master_ip'       => master_ip,
        'max_header_size' => max_header_size,
      )
    end

    let (:apache_api_proxy_address) do
      Noop.hiera('apache_api_proxy_address', '0.0.0.0')
    end

    it 'should declare apache::vhost apache_api_proxy' do
      should contain_apache__vhost('apache_api_proxy').with(
        'docroot'          => '/var/www/html',
        'ip'               => apache_api_proxy_address,
        'port'             => '8888',
        'add_listen'       => false,
        'error_log_syslog' => 'syslog:local0',
        'log_level'        => 'notice',
        'ip_based'         => true,
      )
    end

    it 'should declare apache::mod::headers' do
      should contain_class('apache::mod::headers')
    end
  end

  test_ubuntu_and_centos manifest
end
