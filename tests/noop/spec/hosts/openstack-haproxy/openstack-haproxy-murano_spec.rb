require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-murano.pp'

describe manifest do
  shared_examples 'catalog' do
    use_murano = Noop.hiera_structure('murano/enabled', false)

    if use_murano
      it "should properly configure murano haproxy based on ssl" do
        public_ssl_murano = Noop.hiera_structure('public_ssl/services', false)
        should contain_openstack__ha__haproxy_service('murano-api').with(
          'order'                  => '180',
          'listen_port'            => 8082,
          'public'                 => true,
          'public_ssl'             => public_ssl_murano,
          'require_service'        => 'murano_api',
          'haproxy_config_options' => {
            'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
        )
      end

      it "should properly configure murano rabbitmq haproxy" do
        public_ssl_murano = Noop.hiera_structure('public_ssl/services', false)
        should contain_openstack__ha__haproxy_service('murano_rabbitmq').with(
          'order'                  => '190',
          'listen_port'            => 55572,
          'internal'               => false,
          'haproxy_config_options' => {
            'option'         => ['tcpka'],
            'timeout client' => '48h',
            'timeout server' => '48h',
            'balance'        => 'roundrobin',
            'mode'           => 'tcp',
          },
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end

