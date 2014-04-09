require 'spec_helper'

describe 'nova::conductor' do

  let :pre_condition do
    'include nova'
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_behaves_like 'generic nova service', {
      :name         => 'nova-conductor',
      :package_name => 'nova-conductor',
      :service_name => 'nova-conductor' }
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_behaves_like 'generic nova service', {
      :name         => 'nova-conductor',
      :package_name => 'openstack-nova-conductor',
      :service_name => 'openstack-nova-conductor' }
  end
end
