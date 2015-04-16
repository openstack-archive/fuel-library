require 'spec_helper'
require 'shared-examples'
manifest = 'firewall/firewall.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should properly restrict rabbitmq admin traffic' do
      should contain_firewall('005 local rabbitmq admin').with(
        'sport'   => [ 15672 ],
        'iniface' => 'lo',
        'proto'   => 'tcp',
        'action'  => 'accept'
      )
      should contain_firewall('006 reject non-local rabbitmq admin').with(
        'sport'   => [ 15672 ],
        'iniface' => '! lo',
        'proto'   => 'tcp',
        'action'  => 'drop'
      )
    end
  end

  test_ubuntu_and_centos manifest
end

