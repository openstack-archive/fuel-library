require 'spec_helper'

describe 'nova::cert' do

  let :pre_condition do
    'include nova'
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_behaves_like 'generic nova service', {
      :name         => 'nova-cert',
      :package_name => 'nova-cert',
      :service_name => 'nova-cert' }
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_behaves_like 'generic nova service', {
      :name         => 'nova-cert',
      :package_name => 'openstack-nova-cert',
      :service_name => 'openstack-nova-cert' }
  end
end
