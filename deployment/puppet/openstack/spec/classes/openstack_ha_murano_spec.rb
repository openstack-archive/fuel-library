require 'spec_helper'

  describe 'openstack::ha::murano' do
    let(:params) { {:internal_virtual_ip => '127.0.0.1',
                    :ipaddresses         => ['127.0.0.2', '127.0.0.3'],
                    :public_virtual_ip   => '192.168.0.1',
                    :server_names        => ['node-1', 'node-2'],
                    :public_ssl          => true,
                    :public_ssl_path     => '/var/lib/fuel/haproxy/public_murano.pem',
                 } }
    let(:facts) { {:kernel => 'Linux',
                   :concat_basedir => '/var/lib/puppet/concat',
                   :fqdn           => 'some.host.tld'
                } }

    it "should properly configure murano haproxy based on ssl" do
      should contain_openstack__ha__haproxy_service('murano-api').with(
        'order'                  => '190',
        'listen_port'            => 8082,
        'public'                 => true,
        'public_ssl'             => true,
        'public_ssl_path'        => '/var/lib/fuel/haproxy/public_murano.pem',
        'require_service'        => 'murano_api',
        'haproxy_config_options' => {
          'option'       => 'http-buffer-request',
          'timeout'      => 'http-request 10s',
          'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        },
      )
    end
    it "should properly configure murano haproxy based on ssl" do
      should contain_openstack__ha__haproxy_service('murano_rabbitmq').with(
        'order'                  => '191',
        'listen_port'            => 55572,
        'define_backups'         => true,
        'internal'               => false,
        'public'                 => true,
        'haproxy_config_options' => {
          'option'         => ['tcpka'],
          'timeout client' => '48h',
          'timeout server' => '48h',
          'balance'        => 'roundrobin',
          'mode'           => 'tcp'
        },
        'balancermember_options' => 'check inter 5000 rise 2 fall 3',
      )
    end
  end
