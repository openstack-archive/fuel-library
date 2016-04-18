require 'spec_helper'

  describe 'openstack::ha::cinder' do
    let(:params) { {:internal_virtual_ip => '127.0.0.1',
                    :ipaddresses         => ['127.0.0.2', '127.0.0.3'],
                    :public_virtual_ip   => '192.168.0.1',
                    :server_names        => ['node-1', 'node-2'],
                    :public_ssl          => true,
                    :public_ssl_path     => '/var/lib/fuel/haproxy/public_cinder.pem',
                 } }
    let(:facts) { {:osfamily       => 'Debian',
                   :concat_basedir => '/var/lib/puppet/concat',
                   :fqdn           => 'some.host.tld'
                } }

    it "should properly configure cinder haproxy based on ssl" do
      should contain_openstack__ha__haproxy_service('cinder-api').with(
        'listen_port'            => 8776,
        'public'                 => true,
        'public_ssl'             => true,
        'public_ssl_path'        => '/var/lib/fuel/haproxy/public_cinder.pem',
        'require_service'        => 'cinder-api',
        'haproxy_config_options' => {
          'option'       => ['httpchk', 'httplog','httpclose'],
          'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        },
        'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
      )
    end
  end
