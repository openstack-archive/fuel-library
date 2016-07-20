require 'spec_helper'

describe 'openstack::ha::keystone' do
  let(:facts) do
    { :kernel         => 'Linux',
      :concat_basedir => '/var/lib/puppet/concat',
      :fqdn           => 'some.host.tld',
    }
  end

  context 'default parameters' do
    let(:params) do
      { :internal_virtual_ip => '127.0.0.1',
        :ipaddresses         => ['127.0.0.2', '127.0.0.3'],
        :public_virtual_ip   => '192.168.0.1',
        :server_names        => ['node-1', 'node-2'],
        :public_ssl          => true,
        :public_ssl_path     => '/var/lib/fuel/haproxy/public_keystone.pem',
      }
    end

    it "should properly configure keystone haproxy based on ssl" do
      should contain_openstack__ha__haproxy_service('keystone-1').with(
        'order'                  => '020',
        'listen_port'            => 5000,
        'public'                 => true,
        'public_ssl'             => true,
        'public_ssl_path'        => '/var/lib/fuel/haproxy/public_keystone.pem',
        'haproxy_config_options' => {
          'option'       => ['httpchk GET /v3', 'httplog', 'httpclose', 'http-buffer-request', 'forwardfor'],
          'timeout'      => 'http-request 10s',
          'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        },
        'balancermember_options' => 'check inter 10s fastinter 2s downinter 2s rise 30 fall 3',
      )
    end

    it "should properly configure keystone admin haproxy without ssl" do
      should contain_openstack__ha__haproxy_service('keystone-2').with(
        'order'                  => '030',
        'listen_port'            => 35357,
        'public'                 => false,
        'haproxy_config_options' => {
          'option'       => ['httpchk GET /v3', 'httplog', 'httpclose', 'http-buffer-request', 'forwardfor'],
          'timeout'      => 'http-request 10s',
          'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        },
        'balancermember_options' => 'check inter 10s fastinter 2s downinter 2s rise 30 fall 3',
      )
    end
  end

  context 'with keystone federation' do
    let(:params) do
      { :internal_virtual_ip => '127.0.0.1',
        :ipaddresses         => ['127.0.0.2', '127.0.0.3'],
        :public_virtual_ip   => '192.168.0.1',
        :server_names        => ['node-1', 'node-2'],
        :public_ssl          => true,
        :public_ssl_path     => '/var/lib/fuel/haproxy/public_keystone.pem',
        :federation_enabled  => true,
      }
    end

    it "should properly configure keystone haproxy based on ssl" do
      should contain_openstack__ha__haproxy_service('keystone-1').with(
        'order'                  => '020',
        'listen_port'            => 5000,
        'public'                 => true,
        'public_ssl'             => true,
        'public_ssl_path'        => '/var/lib/fuel/haproxy/public_keystone.pem',
        'haproxy_config_options' => {
          'option'       => ['httpchk GET /v3', 'httplog', 'httpclose', 'http-buffer-request', 'forwardfor'],
          'timeout'      => 'http-request 10s',
          'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          'stick'        => ['on src'],
          'stick-table'  => ['type ip size 200k expire 2m'],
        },
        'balancermember_options' => 'check inter 10s fastinter 2s downinter 2s rise 30 fall 3',
      )
    end

    it "should properly configure keystone admin haproxy without ssl" do
      should contain_openstack__ha__haproxy_service('keystone-2').with(
        'order'                  => '030',
        'listen_port'            => 35357,
        'public'                 => false,
        'haproxy_config_options' => {
          'option'       => ['httpchk GET /v3', 'httplog', 'httpclose', 'http-buffer-request', 'forwardfor'],
          'timeout'      => 'http-request 10s',
          'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
          'stick'        => ['on src'],
          'stick-table'  => ['type ip size 200k expire 2m'],
        },
        'balancermember_options' => 'check inter 10s fastinter 2s downinter 2s rise 30 fall 3',
      )
    end

  end
end
