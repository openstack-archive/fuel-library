require 'spec_helper'

  describe 'openstack::ha::keystone' do
    let(:params) { {:internal_virtual_ip => '127.0.0.1',
                    :ipaddresses         => ['127.0.0.2', '127.0.0.3'],
                    :public_virtual_ip   => '192.168.0.1',
                    :server_names        => ['node-1', 'node-2'],
                    :public_ssl          => true,
                    :public_ssl_path     => '/var/lib/fuel/haproxy/public_keystone.pem',
                 } }
    let(:facts) { {:kernel => 'Linux',
                   :concat_basedir => '/var/lib/puppet/concat',
                   :fqdn           => 'some.host.tld'
                } }

    it "should properly configure keystone haproxy based on ssl" do
      should contain_openstack__ha__haproxy_service('keystone-1').with(
        'order'                  => '020',
        'listen_port'            => 5000,
        'public'                 => true,
        'public_ssl'             => true,
        'public_ssl_path'        => '/var/lib/fuel/haproxy/public_keystone.pem',
        'haproxy_config_options' => {
          'option'       => ['httpchk', 'httplog','httpclose'],
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
          'option'       => ['httpchk', 'httplog','httpclose'],
          'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        },
        'balancermember_options' => 'check inter 10s fastinter 2s downinter 2s rise 30 fall 3',
      )
    end
  end
