require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-nova.pp'

describe manifest do
  shared_examples 'catalog' do
    use_nova = Noop.hiera_structure('nova/enabled', true)

    if use_nova and !Noop.hiera('external_lb', false)
      it "should properly configure nova haproxy based on ssl" do
        public_ssl_nova = Noop.hiera_structure('public_ssl/services', false)
        should contain_openstack__ha__haproxy_service('nova-api-1').with(
          'order'                  => '040',
          'listen_port'            => 8773,
          'public'                 => true,
          'public_ssl'             => public_ssl_nova,
          'require_service'        => 'nova-api',
          'haproxy_config_options' => {
            'timeout server' => '600s',
            'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
        )
        should contain_openstack__ha__haproxy_service('nova-api-2').with(
          'order'                  => '050',
          'listen_port'            => 8774,
          'public'                 => true,
          'public_ssl'             => public_ssl_nova,
          'require_service'        => 'nova-api',
          'haproxy_config_options' => {
            'timeout server' => '600s',
            'option'         => ['httpchk', 'httplog', 'httpclose'],
            'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
          'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
        )
      end
      it "should properly configure nova-metadata-api haproxy" do
        should contain_openstack__ha__haproxy_service('nova-metadata-api').with(
          'order'                  => '060',
          'listen_port'            => 8775,
          'haproxy_config_options' => {
            'option'         => ['httpchk', 'httplog', 'httpclose'],
          },
          'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
        )
      end
      it "should properly configure nova-novncproxy haproxy based on ssl" do
        public_ssl_nova = Noop.hiera_structure('public_ssl/services', false)
        should contain_openstack__ha__haproxy_service('nova-novncproxy').with(
          'order'                  => '170',
          'listen_port'            => 6080,
          'public'                 => true,
          'public_ssl'             => public_ssl_nova,
          'internal'               => false,
          'require_service'        => 'nova-vncproxy',
          'haproxy_config_options' => {
            'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end

