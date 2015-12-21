require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-horizon.pp'

describe manifest do
  shared_examples 'catalog' do
    unless Noop.hiera('external_lb', false)
      it "should properly configure horizon haproxy based on ssl" do
        public_ssl_horizon = Noop.hiera_structure('public_ssl/horizon', false)
        if public_ssl_horizon
          # http horizon should redirect to ssl horizon
          should contain_openstack__ha__haproxy_service('horizon').with(
            'server_names'           => nil,
            'ipaddresses'            => nil,
            'haproxy_config_options' => {
              'redirect' => 'scheme https if !{ ssl_fc }'
            }
          )
          should_not contain_haproxy__balancermember('horizon')
          should contain_openstack__ha__haproxy_service('horizon-ssl').with(
            'order'                  => '017',
            'listen_port'            => 443,
            'balancermember_port'    => 80,
            'public_ssl'             => public_ssl_horizon,
            'haproxy_config_options' => {
              'option'      => ['forwardfor', 'httpchk', 'httpclose', 'httplog'],
              'stick-table' => 'type ip size 200k expire 30m',
              'stick'       => 'on src',
              'balance'     => 'source',
              'timeout'     => ['client 3h', 'server 3h'],
              'mode'        => 'http',
              'reqadd'      => 'X-Forwarded-Proto:\ https',
            },
            'balancermember_options' => 'weight 1 check'
          )
          should contain_haproxy__balancermember('horizon-ssl')
        else
          # http horizon only
          should contain_openstack__ha__haproxy_service('horizon').with(
            'haproxy_config_options' => {
              'option'      => ['forwardfor', 'httpchk', 'httpclose', 'httplog'],
              'stick-table' => 'type ip size 200k expire 30m',
              'stick'       => 'on src',
              'balance'     => 'source',
              'timeout'     => ['client 3h', 'server 3h'],
              'mode'        => 'http',
              'reqadd'      => 'X-Forwarded-Proto:\ https',
            }
          )
          should contain_haproxy__balancermember('horizon')
          should_not contain_openstack__ha__haproxy_service('horizon-ssl')
          should_not contain_haproxy__balancermember('horizon-ssl')
        end
      end
    end
  end

  test_ubuntu_and_centos manifest
end

