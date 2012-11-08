require 'spec_helper'

describe 'swift::storage' do
  # TODO I am not testing the upstart code b/c it should be temporary

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian'
    }
  end

  describe 'when required classes are specified' do
    let :pre_condition do
      "class { 'swift': swift_hash_suffix => 'changeme' }
       include ssh::server::install
      "
    end

    describe 'when the local net ip is specified' do
      let :params do
        {
          :storage_local_net_ip => '127.0.0.1',
        }
      end
    end
    describe 'when local net ip is not specified' do
      it 'should fail' do
        expect { subject }.to raise_error(Puppet::Error, /Must pass storage_local_net_ip/)
      end
    end
  end
  describe 'when the dependencies are not specified' do
    it 'should fail' do
      expect { subject }.to raise_error(Puppet::Error)
    end
  end
end
