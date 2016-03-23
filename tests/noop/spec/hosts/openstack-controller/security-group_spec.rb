require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-controller/openstack-controller.pp'

describe manifest do

  shared_examples 'catalog' do
    it 'should create default security groups' do
      if Noop.puppet_function('pick', nova_hash['create_default_security_groups'], true)
        should contain_nova_security_group('global_http')

        should contain_nova_security_rule('http_01').with(
          'ip_protocol' => 'tcp',
          'from_port' => '80',
          'to_port' => '80',
          'ip_range' => '0.0.0.0/0',
          'security_group' => 'global_http'
        )
        should contain_nova_security_rule('http_02').with(
          'ip_protocol' => 'tcp',
          'from_port' => '443',
          'to_port' => '443',
          'ip_range' => '0.0.0.0/0',
          'security_group' => 'global_http'
        )

        should contain_nova_security_group('global_ssh')

        should contain_nova_security_rule('ssh_01').with(
          'ip_protocol' => 'tcp',
          'from_port' => '22',
          'to_port' => '22',
          'ip_range' => '0.0.0.0/0',
          'security_group' => 'global_ssh'
        )

        should contain_nova_security_group('allow_all')

        should contain_nova_security_rule('all_01').with(
          'ip_protocol' => 'tcp',
          'from_port' => '1',
          'to_port' => '65535',
          'ip_range' => '0.0.0.0/0',
          'security_group' => 'allow_all'
        )
        should contain_nova_security_rule('all_02').with(
          'ip_protocol' => 'udp',
          'from_port' => '1',
          'to_port' => '65535',
          'ip_range' => '0.0.0.0/0',
          'security_group' => 'allow_all'
        )
        should contain_nova_security_rule('all_03').with(
          'ip_protocol' => 'icmp',
          'from_port' => '1',
          'to_port' => '255',
          'ip_range' => '0.0.0.0/0',
          'security_group' => 'allow_all'
        )
      else
        should contain_nova_security_group('global_http').with('ensure' => 'absent')
        should contain_nova_security_group('global_ssh').with('ensure' => 'absent')
        should contain_nova_security_group('allow_all').with('ensure' => 'absent')
      end
    end
  end # end of shared_examples

  test_ubuntu_and_centos manifest
end
