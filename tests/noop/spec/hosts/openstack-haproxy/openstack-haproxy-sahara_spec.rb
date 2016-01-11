require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-sahara.pp'

describe manifest do
  shared_examples 'catalog' do
    use_sahara = Noop.hiera_structure('sahara/enabled', false)

    if use_sahara and !Noop.hiera('external_lb', false)
      it "should properly configure sahara haproxy based on ssl" do
        public_ssl_sahara = Noop.hiera_structure('public_ssl/services', false)
        should contain_openstack__ha__haproxy_service('sahara').with(
          'order'                  => '150',
          'listen_port'            => 8386,
          'public'                 => true,
          'public_ssl'             => public_ssl_sahara,
          'require_service'        => 'sahara-api',
          'haproxy_config_options' => {
            'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          },
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end

