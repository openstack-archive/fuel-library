require 'spec_helper'

  describe 'openstack::ha::ceilometer' do
    let(:params) { {:internal_virtual_ip => '127.0.0.1',
                    :ipaddresses         => ['127.0.0.2', '127.0.0.3'],
                    :public_virtual_ip   => '192.168.0.1',
                    :server_names        => ['node-1', 'node-2'],
                    :public_ssl          => true,
                    :public_ssl_path     => '/var/lib/fuel/haproxy/public_ceilometer.pem',
                 } }
    let(:facts) { {:kernel => 'Linux',
                   :concat_basedir => '/var/lib/puppet/concat',
                   :fqdn           => 'some.host.tld'
                } }

    it "should properly configure ceilometer haproxy based on ssl" do
      should contain_openstack__ha__haproxy_service('ceilometer').with(
        'order'                  => '140',
        'listen_port'            => 8777,
        'public'                 => true,
        'public_ssl'             => true,
        'public_ssl_path'        => '/var/lib/fuel/haproxy/public_ceilometer.pem',
        'require_service'        => 'ceilometer-api',
        'haproxy_config_options' => {
          'option'       => ['httplog', 'forceclose', 'http-buffer-request'],
          'timeout'      => 'http-request 10s',
          'http-request' => ['set-header X-Forwarded-Proto https if { ssl_fc }', 'del-header X-Forwarded-For'],
        },
      )
    end
  end
