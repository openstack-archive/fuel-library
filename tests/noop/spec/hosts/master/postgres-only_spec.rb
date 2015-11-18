require 'spec_helper'
require 'shared-examples'
manifest = 'master/postgres-only.pp'

describe manifest do
  shared_examples 'catalog' do
    context 'running on CentOS 6' do
      let(:facts) do
        Noop.centos_facts.merge({
          :operatingsystemmajrelease => '6'
        })
      end
      it 'should contain class postgresql::globals with proper bindir' do
        should contain_class('postgresql::globals').with(
          :bindir  => '/usr/pgsql-9.3/bin'
        )
      end
      it 'should contain postgres_configs with proper values' do
        should contain_postgres_config('log_rotation_age').with(
          :value => '7d'
        )
        should contain_postgres_config('log_filename').with(
          :value => "'pgsql'"
        )
        should contain_postgres_config('log_directory').with(
          :value => "'/var/log/'"
        )
      end
    end
    context 'running on CentOS 7' do
      let(:facts) do
        Noop.centos_facts.merge({
          :operatingsystemmajrelease => '7'
        })
      end
      it 'should contain class postgresql::globals with proper bindir' do
        should contain_class('postgresql::globals').with(
          :bindir => nil
        )
      end
    end
  end
  test_centos manifest
end
