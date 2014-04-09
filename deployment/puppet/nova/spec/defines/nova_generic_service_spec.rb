require 'spec_helper'

describe 'nova::generic_service' do
  describe 'package should come before service' do
    let :pre_condition do
      'include nova'
    end

    let :params do
      {
        :package_name => 'foo',
        :service_name => 'food',
        :enabled => true
      }
    end

    let :facts do
      { :osfamily => 'Debian' }
    end

    let :title do
      'foo'
    end

    it { should contain_service('nova-foo').with(
      'name'    => 'food',
      'ensure'  => 'running',
      'enable'  => true,
      'require' => ['Package[nova-common]', 'Package[foo]']
    )}
  end
end
