require 'spec_helper'

  describe 'openstack::ha::glance' do
    let(:params) { {:internal_virtual_ip => '127.0.0.1',
                    :ipaddresses         => ['127.0.0.2', '127.0.0.3'],
                    :public_virtual_ip   => '192.168.0.1',
                    :server_names        => ['node-1', 'node-2'],
                    :public_ssl          => true,
                    :public_ssl_path     => '/var/lib/fuel/haproxy/public_glance.pem',
                 } }
    let(:facts) { {:kernel => 'Linux',
                   :concat_basedir => '/var/lib/puppet/concat',
                   :fqdn           => 'some.host.tld'
                } }

    it "should properly configure glance haproxy based on ssl" do
      should contain_openstack__ha__haproxy_service('glance-api').with(
        'order'                  => '080',
        'listen_port'            => 9292,
        'public'                 => true,
        'public_ssl'             => true,
        'public_ssl_path'        => '/var/lib/fuel/haproxy/public_glance.pem',
        'require_service'        => 'glance-api',
        'haproxy_config_options' => {
          'option'       => ['httpchk GET /healthcheck', 'httplog', 'forceclose', 'http-buffer-request'],
          'timeout'      => ['server 11m', 'http-request 10s'],
          'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        },
        'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
      )
    end
    it "should properly configure glance haproxy based on ssl" do
      should contain_openstack__ha__haproxy_service('glare').with(
        'order'                  => '081',
        'listen_port'            => 9494,
        'public'                 => true,
        'public_ssl'             => true,
        'public_ssl_path'        => '/var/lib/fuel/haproxy/public_glance.pem',
        'require_service'        => 'glare',
        'haproxy_config_options' => {
          'option'       => ['httpchk /versions', 'httplog', 'http-server-close', 'http-buffer-request'],
          'timeout'      => ['server 11m', 'http-request 10s'],
          'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        },
        'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
      )
    end
    it "should properly configure glance-registry" do
      should contain_openstack__ha__haproxy_service('glance-registry').with(
        'order'                  => '090',
        'listen_port'            => 9191,
        'haproxy_config_options' => {
          'timeout' => 'server 11m',
        },
      )
    end
  end
