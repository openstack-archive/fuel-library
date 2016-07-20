require 'spec_helper'

  describe 'openstack::ha::neutron' do
    let(:params) { {:internal_virtual_ip => '127.0.0.1',
                    :ipaddresses         => ['127.0.0.2', '127.0.0.3'],
                    :public_virtual_ip   => '192.168.0.1',
                    :server_names        => ['node-1', 'node-2'],
                    :public_ssl          => true,
                    :public_ssl_path     => '/var/lib/fuel/haproxy/public_neutron.pem',
                 } }
    let(:facts) { {:kernel => 'Linux',
                   :concat_basedir => '/var/lib/puppet/concat',
                   :fqdn           => 'some.host.tld'
                } }

    it "should properly configure neutron haproxy based on ssl" do
      should contain_openstack__ha__haproxy_service('neutron').with(
        'order'                  => '085',
        'listen_port'            => 9696,
        'public'                 => true,
        'public_ssl'             => true,
        'public_ssl_path'        => '/var/lib/fuel/haproxy/public_neutron.pem',
        'haproxy_config_options' => {
          'option'       => ['httpchk', 'httplog', 'httpclose', 'http-buffer-request'],
          'timeout'      => 'http-request 10s',
          'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        },
        'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
      )
    end
  end
