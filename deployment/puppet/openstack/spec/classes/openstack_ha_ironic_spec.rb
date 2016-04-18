require 'spec_helper'

  describe 'openstack::ha::ironic' do
    let(:params) { {:internal_virtual_ip  => '127.0.0.1',
                    :ipaddresses          => ['127.0.0.2', '127.0.0.3'],
                    :public_virtual_ip    => '192.168.0.1',
                    :baremetal_virtual_ip => '192.168.0.2',
                    :server_names         => ['node-1', 'node-2'],
                    :public_ssl           => true,
                    :public_ssl_path      => '/var/lib/fuel/haproxy/public_ironic.pem',
                 } }
    let(:facts) { {:osfamily       => 'Debian',
                   :concat_basedir => '/var/lib/puppet/concat',
                   :fqdn           => 'some.host.tld'
                } }

    it "should properly configure ironic haproxy based on ssl" do
      should contain_openstack__ha__haproxy_service('ironic').with(
        'listen_port'            => 6385,
        'public'                 => true,
        'public_ssl'             => true,
        'public_ssl_path'        => '/var/lib/fuel/haproxy/public_ironic.pem',
        'haproxy_config_options' => {
          'option'       => ['httpchk GET /', 'httplog','httpclose'],
          'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        },
      )
    end

    it "should properly configure ironic haproxy on baremetal VIP" do
      should contain_openstack__ha__haproxy_service('ironic-baremetal').with(
        'listen_port'            => 6385,
        'public_ssl'             => false,
        'internal_virtual_ip'    => '192.168.0.2',
        'haproxy_config_options' => {
          'option'       => ['httpchk GET /', 'httplog','httpclose'],
          'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        },
      )
    end
  end
