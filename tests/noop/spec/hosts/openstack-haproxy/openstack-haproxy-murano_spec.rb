require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-murano.pp'

describe manifest do
  shared_examples 'catalog' do
    use_murano = Noop.hiera_structure('murano/enabled', false)
    use_cfapi_murano = Noop.hiera_structure('murano-cfapi/enabled', false)

    if use_murano and !Noop.hiera('external_lb', false)
      it "should properly configure murano haproxy based on ssl" do
        public_ssl_murano = Noop.hiera_structure('public_ssl/services', false)
        should contain_openstack__ha__haproxy_service('murano-api').with(
          'order'                  => '190',
          'listen_port'            => 8082,
          'public'                 => true,
          'public_ssl'             => public_ssl_murano,
          'require_service'        => 'murano_api',
          'haproxy_config_options' => {
            'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
        )
      end

      if use_cfapi_murano
        it "should properly configure murano-cfapi haproxy based on ssl" do
          public_ssl_murano = Noop.hiera_structure('public_ssl/services', false)
          should contain_openstack__ha__haproxy_service('murano-cfapi').with(
            'order'                  => '192',
            'listen_port'            => 8083,
            'public'                 => true,
            'public_ssl'             => public_ssl_murano,
            'require_service'        => 'murano_cfapi',
            'haproxy_config_options' => {
              'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
            },
          )
        end
      end

      it "should properly configure murano rabbitmq haproxy" do
        public_ssl_murano = Noop.hiera_structure('public_ssl/services', false)
        should contain_openstack__ha__haproxy_service('murano_rabbitmq').with(
          'order'                  => '191',
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

