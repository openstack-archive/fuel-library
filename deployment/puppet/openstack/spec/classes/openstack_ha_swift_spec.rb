require 'spec_helper'

  describe 'openstack::ha::swift' do
    let(:params) { {:internal_virtual_ip  => '127.0.0.1',
                    :ipaddresses          => ['127.0.0.2', '127.0.0.3'],
                    :public_virtual_ip    => '192.168.0.1',
                    :baremetal_virtual_ip => '192.168.0.2',
                    :server_names         => ['node-1', 'node-2'],
                    :public_ssl           => true,
                 } }
    let(:facts) { {:kernel => 'Linux',
                   :concat_basedir => '/var/lib/puppet/concat',
                   :fqdn           => 'some.host.tld'
                } }

    it "should properly configure swift haproxy based on ssl" do
      should contain_openstack__ha__haproxy_service('swift').with(
        'order'                  => '120',
        'listen_port'            => 8080,
        'public'                 => true,
        'public_ssl'             => true,
        'haproxy_config_options' => {
          'option'       => ['httpchk', 'httplog','httpclose'],
          'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        },
      )
    end

    it "should properly configure swift haproxy on baremetal VIP" do
      should contain_openstack__ha__haproxy_service('swift-baremetal').with(
        'order'                  => '125',
        'listen_port'            => 8080,
        'public_ssl'             => false,
        'internal_virtual_ip'    => '192.168.0.2',
        'haproxy_config_options' => {
          'option'       => ['httpchk', 'httplog','httpclose'],
          'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        },
      )
    end
  end
