require 'spec_helper'

describe 'cluster::heat_engine' do
  let(:pre_condition) do
    "class { '::heat::engine': auth_encryption_key => 'deadb33fdeadb33f' }"
  end

  shared_examples_for 'cluster::heat_engine configuration' do
    context 'with valid params' do
      let :params do
        { }
      end

      it {
        should contain_class('cluster::heat_engine')
      }

      it 'configures a heat engine pacemaker service' do
        should contain_pacemaker__service(platform_params[:engine_service_name]).with(
          :primitive_type => 'heat-engine',
          :metadata       => {
            'resource-stickiness' => '1',
            'migration-threshold' => '3'
          },
          :complex_type   => 'clone',
          :complex_metadata => {
            'interleave' => true
          },
          :operations     => {
            'monitor' => {
              'interval' => '20',
              'timeout'  => '30'
            },
            'start'   => {
              'interval' => '0',
              'timeout'  => '60'
            },
            'stop'    => {
              'interval' => '0',
              'timeout'  => '60'
            },
          }
        )
      end
    end
  end

  on_supported_os(supported_os: supported_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts.merge(common_facts) }

      let :platform_params do
        if facts[:osfamily] == 'Debian'
          {
              :engine_service_name => 'heat-engine'
          }
        else
          {
              :engine_service_name => 'openstack-heat-engine'
          }
        end
      end

      it_configures 'cluster::heat_engine configuration'
    end
  end

end

