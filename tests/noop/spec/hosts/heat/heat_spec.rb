require 'spec_helper'
require 'shared-examples'
manifest = 'heat/heat.pp'

describe manifest do
  shared_examples 'catalog' do

    use_syslog = Noop.hiera 'use_syslog'

    it 'should set empty trusts_delegated_roles for heat engine' do
      should contain_class('heat::engine').with(
        'trusts_delegated_roles' => [],
      )
      should contain_heat_config('DEFAULT/trusts_delegated_roles').with(
        'value' => [],
      )
    end

    it 'should configure syslog rfc format for heat' do
      should contain_heat_config('DEFAULT/use_syslog_rfc_format').with(:value => use_syslog)
    end

    it 'should configure region name for heat' do
      region = Noop.hiera 'region'
      if !region
        region = 'RegionOne'
      end
      should contain_heat_config('DEFAULT/region_name_for_services').with(
        'value' => region,
      )
    end

    it { should contain_service('httpd').that_comes_before('Class[heat::keystone::domain]') }

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

