require 'spec_helper'

describe 'nova::objectstore' do

  let :pre_condition do
    'include nova'
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_behaves_like 'generic nova service', {
      :name         => 'nova-objectstore',
      :package_name => 'nova-objectstore',
      :service_name => 'nova-objectstore' }
    it { should contain_nova_config('DEFAULT/s3_listen').with_value('0.0.0.0') }

    context 'with custom bind parameter' do
      let :params do
        { :bind_address => '192.168.0.1'}
      end
      it { should contain_nova_config('DEFAULT/s3_listen').with_value('192.168.0.1') }
    end

  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_behaves_like 'generic nova service', {
      :name         => 'nova-objectstore',
      :package_name => 'openstack-nova-objectstore',
      :service_name => 'openstack-nova-objectstore' }
    it { should contain_nova_config('DEFAULT/s3_listen').with_value('0.0.0.0')}

    context 'with custom bind parameter' do
      let :params do
        { :bind_address => '192.168.0.1'}
      end
      it { should contain_nova_config('DEFAULT/s3_listen').with_value('192.168.0.1') }
    end

  end
end
