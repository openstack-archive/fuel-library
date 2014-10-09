describe 'swift::storage::node' do

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
      :processorcount  => 1,
      :concat_basedir  => '/var/lib/puppet/concat',
    }
  end

  let :params do
    {
      :zone => "1",
      :mnt_base_dir => '/srv/node'
    }
  end

  let :title do
    "1"
  end

  let :pre_condition do
    "class { 'ssh::server::install': }
     class { 'swift': swift_hash_suffix => 'foo' }
     class { 'swift::storage': storage_local_net_ip => '127.0.0.1' }"
  end

  it {
    should contain_ring_object_device("127.0.0.1:6010/1")
    should contain_ring_container_device("127.0.0.1:6011/1")
    should contain_ring_account_device("127.0.0.1:6012/1")
  }

  context 'when zone is not a number' do
     let(:title) { '1' }
     let :params do
     { :zone => 'invalid',
       :mnt_base_dir => '/srv/node' }
     end

    it 'should raise an error' do
      expect {
        subject
      }.to raise_error(Puppet::Error, /The zone parameter must be an integer/)
    end
  end
end
