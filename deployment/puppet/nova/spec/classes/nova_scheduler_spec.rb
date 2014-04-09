require 'spec_helper'

describe 'nova::scheduler' do

  let :pre_condition do
    'include nova'
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_behaves_like 'generic nova service', {
      :name         => 'nova-scheduler',
      :package_name => 'nova-scheduler',
      :service_name => 'nova-scheduler' }
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_behaves_like 'generic nova service', {
      :name         => 'nova-scheduler',
      :package_name => 'openstack-nova-scheduler',
      :service_name => 'openstack-nova-scheduler' }
  end
end
