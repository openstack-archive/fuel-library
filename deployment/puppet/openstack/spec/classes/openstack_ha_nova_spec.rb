require 'spec_helper'

  describe 'openstack::ha::nova' do
    let(:params) { {:internal_virtual_ip => '127.0.0.1',
                    :ipaddresses         => ['127.0.0.2', '127.0.0.3'],
                    :public_virtual_ip   => '192.168.0.1',
                    :server_names        => ['node-1', 'node-2'],
                    :public_ssl          => true,
                    :public_ssl_path     => '/var/lib/fuel/haproxy/public_nova.pem',
                 } }
    let(:facts) { {:osfamily       => 'Debian',
                   :concat_basedir => '/var/lib/puppet/concat',
                   :fqdn           => 'some.host.tld'
                } }

    it "should properly configure nova compute API haproxy based on ssl" do
      should contain_openstack__ha__haproxy_service('nova-api').with(
        'listen_port'            => 8774,
        'public'                 => true,
        'public_ssl'             => true,
        'public_ssl_path'        => '/var/lib/fuel/haproxy/public_nova.pem',
        'require_service'        => 'nova-api',
        'haproxy_config_options' => {
          'option'         => ['httpchk', 'httplog', 'httpclose'],
          'timeout server' => '600s',
          'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        },
        'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
      )
    end
    it "should properly configure nova metadata API haproxy based on ssl" do
      should contain_openstack__ha__haproxy_service('nova-metadata-api').with(
        'listen_port'            => 8775,
        'haproxy_config_options' => {
          'option'         => ['httpchk', 'httplog', 'httpclose'],
        },
        'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
      )
    end
    it "should properly configure nova novncproxy haproxy based on ssl" do
      should contain_openstack__ha__haproxy_service('nova-novncproxy').with(
        'listen_port'            => 6080,
        'public'                 => true,
        'public_ssl'             => true,
        'public_ssl_path'        => '/var/lib/fuel/haproxy/public_nova.pem',
        'internal'               => false,
        'require_service'        => 'nova-vncproxy',
        'haproxy_config_options' => {
          'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        },
      )
    end

  end
