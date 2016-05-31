require 'spec_helper'

  describe 'openstack::ha::swift' do
    let(:facts) do
      {
        :kernel => 'Linux',
        :concat_basedir => '/var/lib/puppet/concat',
        :fqdn           => 'some.host.tld'
      }
    end

    let(:bm_opt_tail) { 'inter 15s fastinter 2s downinter 8s rise 3 fall 3' }

    let(:haproxy_config_opts) do
      {
        'option'       => [@http_check, 'httplog', 'httpclose', 'tcp-smart-accept', 'tcp-smart-connect'],
        'http-request' => 'set-header X-Forwarded-Proto https if { ssl_fc }',
      }
    end

    before :each do
      if params[:bind_to_one]
        @http_check = 'httpchk HEAD /healthcheck HTTP/1.0'
        @balancermember_options = "check #{bm_opt_tail}"
      else
        @http_check = 'httpchk'
        @balancermember_options = "check port 49001 #{bm_opt_tail}"
      end
    end

    context 'with custom params' do
      let(:params) do
        {
            :internal_virtual_ip  => '127.0.0.1',
            :ipaddresses          => ['127.0.0.2', '127.0.0.3'],
            :public_virtual_ip    => '192.168.0.1',
            :baremetal_virtual_ip => '192.168.0.2',
            :server_names         => ['node-1', 'node-2'],
            :public_ssl           => true,
            :public_ssl_path      => '/var/lib/fuel/haproxy/public_swift.pem',
            :bind_to_one          => false,
        }
      end

      it "should properly configure swift haproxy based on ssl" do
        should contain_openstack__ha__haproxy_service('swift').with(
          'order'                  => '120',
          'listen_port'            => 8080,
          'public'                 => true,
          'public_ssl'             => true,
          'public_ssl_path'        => '/var/lib/fuel/haproxy/public_swift.pem',
          'haproxy_config_options' => haproxy_config_opts,
          'balancermember_options' => @balancermember_options,
        )
      end

      it "should properly configure swift haproxy on baremetal VIP" do
        should contain_openstack__ha__haproxy_service('swift-baremetal').with(
          'order'                  => '125',
          'listen_port'            => 8080,
          'public_ssl'             => false,
          'internal_virtual_ip'    => '192.168.0.2',
          'haproxy_config_options' => haproxy_config_opts,
        )
      end
    end

    context 'with default params' do
      let(:params) do
        {
            :internal_virtual_ip  => '127.0.0.1',
            :ipaddresses          => ['127.0.0.2', '127.0.0.3'],
            :public_virtual_ip    => '192.168.0.1',
            :server_names         => ['node-1', 'node-2'],
            :bind_to_one          => true,
        }
      end

      it "should properly configure swift haproxy" do
        should contain_openstack__ha__haproxy_service('swift').with(
          'order'                  => '120',
          'listen_port'            => 8080,
          'public'                 => true,
          'public_ssl'             => false,
          'haproxy_config_options' => haproxy_config_opts,
          'balancermember_options' => @balancermember_options,
        )
      end
    end
  end
