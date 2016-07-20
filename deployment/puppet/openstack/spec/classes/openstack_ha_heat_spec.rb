require 'spec_helper'

  describe 'openstack::ha::heat' do
    let(:params) { {:internal_virtual_ip => '127.0.0.1',
                    :ipaddresses         => ['127.0.0.2', '127.0.0.3'],
                    :public_virtual_ip   => '192.168.0.1',
                    :server_names        => ['node-1', 'node-2'],
                    :public_ssl          => true,
                    :public_ssl_path     => '/var/lib/fuel/haproxy/public_heat.pem',
                 } }
    let(:facts) { {:kernel => 'Linux',
                   :concat_basedir => '/var/lib/puppet/concat',
                   :fqdn           => 'some.host.tld'
                } }

    it "should properly configure heat haproxy based on ssl" do
      should contain_openstack__ha__haproxy_service('heat-api').with(
        'order'                  => '160',
        'listen_port'            => 8004,
        'public'                 => true,
        'public_ssl'             => true,
        'public_ssl_path'        => '/var/lib/fuel/haproxy/public_heat.pem',
        'require_service'        => 'heat-api',
        'haproxy_config_options' => {
          'option'       => ['httpchk', 'httplog','httpclose', 'http-buffer-request'],
          'timeout'      => ['server 660s', 'http-request 10s'],
          'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        },
        'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
      )
    end

    it "should properly configure heat-api-cfn" do
      should contain_openstack__ha__haproxy_service('heat-api-cfn').with(
        'order'                  => '161',
        'listen_port'            => 8000,
        'public'                 => true,
        'public_ssl'             => true,
        'public_ssl_path'        => '/var/lib/fuel/haproxy/public_heat.pem',
        'require_service'        => 'heat-api',
        'haproxy_config_options' => {
          'option'       => ['httpchk', 'httplog','httpclose', 'http-buffer-request'],
          'timeout'      => ['server 660s', 'http-request 10s'],
          'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        },
        'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
      )
    end

    it "should properly configure heat-api-cfn" do
      should contain_openstack__ha__haproxy_service('heat-api-cloudwatch').with(
        'order'                  => '162',
        'listen_port'            => 8003,
        'public'                 => true,
        'public_ssl'             => true,
        'require_service'        => 'heat-api',
        'haproxy_config_options' => {
          'option'       => ['httpchk', 'httplog','httpclose', 'http-buffer-request'],
          'timeout'      => ['server 660s', 'http-request 10s'],
          'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        },
        'balancermember_options' => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
      )
    end
  end
