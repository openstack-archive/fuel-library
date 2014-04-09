require 'spec_helper'

describe 'nova::consoleauth' do

  let :pre_condition do
    'include nova'
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_behaves_like 'generic nova service', {
      :name         => 'nova-consoleauth',
      :package_name => 'nova-consoleauth',
      :service_name => 'nova-consoleauth' }
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_behaves_like 'generic nova service', {
      :name         => 'nova-consoleauth',
      :package_name => 'openstack-nova-console',
      :service_name => 'openstack-nova-consoleauth' }
  end
end
