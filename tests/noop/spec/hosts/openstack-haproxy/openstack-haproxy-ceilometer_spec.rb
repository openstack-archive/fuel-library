require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-ceilometer.pp'

describe manifest do
  shared_examples 'catalog' do
    use_ceilometer = Noop.hiera_structure('ceilometer/enabled', false)

    if use_ceilometer and !Noop.hiera('external_lb', false)
      it "should properly configure ceilometer haproxy based on ssl" do
        public_ssl_ceilometer = Noop.hiera_structure('public_ssl/services', false)
        should contain_openstack__ha__haproxy_service('ceilometer').with(
          'order'                  => '140',
          'listen_port'            => 8777,
          'public'                 => true,
          'public_ssl'             => public_ssl_ceilometer,
          'require_service'        => 'ceilometer-api',
          'haproxy_config_options' => {
            'option'       => ['httplog', 'forceclose'],
            'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end
