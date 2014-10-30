require 'spec_helper'

describe 'swift::ringbuilder' do
  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
      :processorcount  => 1,
      :concat_basedir  => '/tmp/foo'
    }
  end
  describe 'when swift class is not included' do
    it 'should fail' do
      expect { subject }.to raise_error(Puppet::Error)
    end
  end
  describe 'when swift class is included' do

    let :pre_condition do
      "class { memcached: max_memory => 1}
       class { swift: swift_hash_suffix => string }"
    end

    it 'should rebalance the ring for all ring types' do
      should contain_swift__ringbuilder__rebalance('object')
      should contain_swift__ringbuilder__rebalance('account')
      should contain_swift__ringbuilder__rebalance('container')
    end

    describe 'with default parameters' do
      ['object', 'account', 'container'].each do |type|
        it { should contain_swift__ringbuilder__create(type).with(
          :part_power     => '18',
          :replicas       => '3',
          :min_part_hours => '24'
        )}
      end
    end

    describe 'with parameter overrides' do

      let :params do
        {:part_power     => '19',
         :replicas       => '3',
         :min_part_hours => '2'
        }
      end

      ['object', 'account', 'container'].each do |type|
        it { should contain_swift__ringbuilder__create(type).with(
          :part_power     => '19',
          :replicas       => '3',
          :min_part_hours => '2'
        )}
      end

    end
    describe 'when specifying ring devices' do
      let :pre_condition do
         'class { memcached: max_memory => 1}
          class { swift: swift_hash_suffix => string }
          ring_object_device { "127.0.0.1:6000/1":
          zone        => 1,
          weight      => 1,
        }

        ring_container_device { "127.0.0.1:6001/1":
          zone        => 2,
          weight      => 1,
        }

        ring_account_device { "127.0.0.1:6002/1":
          zone        => 3,
          weight      => 1,
        }'
      end

      it 'should set up all of the correct dependencies' do
        should contain_swift__ringbuilder__create('object').with(
          {:before => 'Ring_object_device[127.0.0.1:6000/1]'}
        )
        should contain_swift__ringbuilder__create('container').with(
        {:before => 'Ring_container_device[127.0.0.1:6001/1]'}
        )
        should contain_swift__ringbuilder__create('account').with(
        {:before => 'Ring_account_device[127.0.0.1:6002/1]'}
        )
        should contain_ring_object_device('127.0.0.1:6000/1').with(
        {:notify => 'Swift::Ringbuilder::Rebalance[object]'}
        )
        should contain_ring_container_device('127.0.0.1:6001/1').with(
        {:notify => 'Swift::Ringbuilder::Rebalance[container]'}
        )
        should contain_ring_account_device('127.0.0.1:6002/1').with(
        {:notify => 'Swift::Ringbuilder::Rebalance[account]'}
        )
      end
    end
  end
end
