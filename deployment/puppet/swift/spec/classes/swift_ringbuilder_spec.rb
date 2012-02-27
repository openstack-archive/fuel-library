require 'spec_helper'

describe 'swift::ringbuilder' do
  let :facts do
    {:operatingsystem => 'Ubuntu',
     :processorcount  => 1
    }
  end
  describe 'when swift class is not included' do
    it 'should fail' do
      expect do
        subject
      end.should raise_error(Puppet::Error)
    end
  end
  describe 'when swift class is included' do

    let :pre_condition do
      "class { memcached: max_memory => 1}
       class { swift: swift_hash_suffix => string }
       class { 'ssh::server::install': }"
    end

    it { should contain_swift__ringbuilder__rebalance('object') }
    it { should contain_swift__ringbuilder__rebalance('account') }
    it { should contain_swift__ringbuilder__rebalance('container') }

    describe 'with default parameters' do
      ['object', 'account', 'container'].each do |type|
        it { should contain_swift__ringbuilder__create(type).with(
          :part_power     => '18',
          :replicas       => '5',
          :min_part_hours => '1'
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
          class { "ssh::server::install": }
          ring_object_device { "127.0.0.1:6000":
          zone        => 1,
          device_name => 1,
          weight      => 1,
        }

        ring_container_device { "127.0.0.1:6001":
          zone        => 2,
          device_name => 1,
          weight      => 1,
        }

        ring_account_device { "127.0.0.1:6002":
          zone        => 3,
          device_name => 1,
          weight      => 1,
        }'
      end

      it { should contain_swift__ringbuilder__create('object').with(
        {:before => 'Ring_object_device[127.0.0.1:6000]'}
      )}
      it { should contain_swift__ringbuilder__create('container').with(
        {:before => 'Ring_container_device[127.0.0.1:6001]'}
      )}
      it { should contain_swift__ringbuilder__create('account').with(
        {:before => 'Ring_account_device[127.0.0.1:6002]'}
      )}
      it { should contain_ring_object_device('127.0.0.1:6000').with(
        {:notify => 'Swift::Ringbuilder::Rebalance[object]'}
      )}
      it { should contain_ring_container_device('127.0.0.1:6001').with(
        {:notify => 'Swift::Ringbuilder::Rebalance[container]'}
      )}
      it { should contain_ring_account_device('127.0.0.1:6002').with(
        {:notify => 'Swift::Ringbuilder::Rebalance[account]'}
      )}
    end
  end
end
