require 'spec_helper'

describe 'nova::conductor' do

  let :pre_condition do
    'include nova'
  end

  context 'on redhat' do

    let :facts do
      { :osfamily => 'redhat' }
    end


    it { should contain_nova__generic_service('conductor').with(
      :enabled        => false,
      :package_name   => 'openstack-nova-conductor',
      :service_name   => 'openstack-nova-conductor',
      :ensure_package => 'present'
    )}

  end

  context 'on debian' do

    let :facts do
      { :osfamily => 'Debian' }
    end

    it { should contain_nova__generic_service('conductor').with(
      :enabled        => false,
      :package_name   => 'nova-conductor',
      :service_name   => 'nova-conductor',
      :ensure_package => 'present'
    )}

  end

  context 'with params' do
    let :facts do
      {:osfamily => 'Debian' }
    end
    let :params do
    { :enabled => true, :ensure_package => 'latest' }
    end

    it { should contain_nova__generic_service('conductor').with(
      :enabled        => true,
      :ensure_package => 'latest'
    ) }
  end
end
