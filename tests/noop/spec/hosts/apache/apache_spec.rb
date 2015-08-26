require 'spec_helper'
require 'shared-examples'
manifest = 'apache/apache.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should execute apache class with given parameters' do
      should contain_class('apache').with(
        'mpm_module'       => 'false',
        'default_vhost'    => 'false',
        'server_tokens'    => 'Prod',
        'server_signature' => 'Off',
        'trace_enable'     => 'Off'
      )
    end
    it 'should apply kernel tweaks for connections' do
      should contain_sysctl__value('net.core.somaxconn').with_value('4096')
      should contain_sysctl__value('net.ipv4.tcp_max_syn_backlog').with_value('8192')
    end

    it {
      should contain_service('httpd').with(
           'hasrestart' => nil,
           'restart'    => nil,
      )
    }

  end
  test_ubuntu_and_centos manifest
end
