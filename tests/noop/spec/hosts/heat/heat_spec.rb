require 'spec_helper'
require 'shared-examples'
manifest = 'heat/heat.pp'

describe manifest do
  shared_examples 'catalog' do

    use_syslog = Noop.hiera 'use_syslog'
    default_log_levels = Noop.hiera_structure 'default_log_levels_hash'

    it 'should configure default log levels' do
      should contain_class('heat::logging').with('default_log_levels' => default_log_levels)
    end

    it 'should set empty trusts_delegated_roles for heat engine' do
      should contain_class('heat::engine').with(
        'trusts_delegated_roles' => [],
      )
      should contain_heat_config('DEFAULT/trusts_delegated_roles').with(
        'value' => [],
      )
    end

    it 'should configure template size and request limit' do
      should contain_heat_config('DEFAULT/max_template_size').with_value('5440000')
      should contain_heat_config('DEFAULT/max_resources_per_stack').with_value('20000')
      should contain_heat_config('DEFAULT/max_json_body_size').with_value('10880000')
    end

    it 'should configure heat rpc response timeout' do
      should contain_heat_config('DEFAULT/rpc_response_timeout').with_value('600')
    end

    it 'should configure syslog rfc format for heat' do
      should contain_heat_config('DEFAULT/use_syslog_rfc_format').with(:value => use_syslog)
    end

    it 'should disable use_stderr for heat' do
      should contain_heat_config('DEFAULT/use_stderr').with(:value => 'false')
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

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

