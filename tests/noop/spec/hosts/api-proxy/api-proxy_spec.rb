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
      apache_api_proxy_address = Noop.puppet_function('get_network_role_property', 'admin/pxe', 'ipaddr')
    end

    it 'should declare apache::vhost apache_api_proxy' do
      should contain_apache__vhost('apache_api_proxy').with(
        'docroot'          => '/var/www/html',
        'ip'               => apache_api_proxy_address,
        'port'             => '8888',
        'add_listen'       => true,
        'error_log_syslog' => 'syslog:local0',
        'log_level'        => 'notice',
        'ip_based'         => true,
      )
    end

    master_ip = Noop.hiera 'master_ip'
    it 'should contain 25-apache_api_proxy.conf with correct statements' do
        should contain_file('/tmp//25-apache_api_proxy.conf/fragments/270_apache_api_proxy-custom_fragment').with(
         'ensure' => 'file',
         'content' => "
  ## Custom fragment
  ProxyRequests on
  ProxyVia On
  AllowCONNECT 443 563 5000 6385 8000 8003 8004 8080 8082 8386 8773 8774 8776 8777 9292 9696
  HostnameLookups off
  LimitRequestFieldSize 81900
  <Proxy *>
    Order Deny,Allow
        Allow from #{master_ip}
        Deny from all
  </Proxy>

"
        )
    end

  end

  test_ubuntu_and_centos manifest
end
