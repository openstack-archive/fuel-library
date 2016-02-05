require 'spec_helper'
require 'shared-examples'
manifest = 'master/postgres-only.pp'

describe manifest do
  shared_examples 'catalog' do
    context 'running on CentOS 6' do
      let(:facts) do
        task.facts_data.merge({
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
        task.facts_data.merge({
          :operatingsystemmajrelease => '7'
        })
      end
      it 'should contain class postgresql::globals with proper bindir' do
        should contain_class('postgresql::globals').with(
          :bindir => nil
        )
      end
    end

    it 'should configure postgres server' do
      should contain_class('postgresql::server').with({
        'listen_addresses' => '0.0.0.0',
        'ip_mask_allow_all_users' => '0.0.0.0/0'
      })
    end

    it 'should configure nailgun database' do
      fuel_settings = task.puppet_function('parseyaml',
                                           facts[:astute_settings_yaml])
      database_name = fuel_settings['postgres']['nailgun_dbname']
      database_user = fuel_settings['postgres']['nailgun_user']
      database_passwd = fuel_settings['postgres']['nailgun_password']

      should contain_class('nailgun::database').with({
        'user' => database_user,
        'password' => database_passwd,
        'dbname' => database_name
      })
    end

    it 'should configure keystone database' do
      fuel_settings = task.puppet_function('parseyaml',
                                           facts[:astute_settings_yaml])
      keystone_dbname = fuel_settings['postgres']['keystone_dbname']
      keystone_dbuser = fuel_settings['postgres']['keystone_user']
      keystone_dbpass = fuel_settings['postgres']['keystone_password']

      should contain_postgresql__server__db("#{keystone_dbname}").with({
        'user'     => keystone_dbuser,
        'password' => keystone_dbpass,
        'grant'    => 'all'
      })
    end

    it 'should configure ostf database' do
      fuel_settings = task.puppet_function('parseyaml',
                                           facts[:astute_settings_yaml])
      ostf_dbname   = fuel_settings['postgres']['ostf_dbname']
      ostf_dbuser   = fuel_settings['postgres']['ostf_user']
      ostf_dbpass   = fuel_settings['postgres']['ostf_password']

      should contain_postgresql__server__db("#{ostf_dbname}").with({
        'user'     => ostf_dbuser,
        'password' => ostf_dbpass,
        'grant'    => 'all'
      })
    end

  end
  test_centos manifest
end
