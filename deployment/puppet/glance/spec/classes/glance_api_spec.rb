require 'spec_helper'

describe 'glance::api' do

  let :facts do
    {
      :osfamily => 'Debian',
      :processorcount => '7',
    }
  end

  let :default_params do
    {
      :verbose           => 'False',
      :debug             => 'False',
      :bind_host         => '0.0.0.0',
      :bind_port         => '9292',
      :registry_host     => '0.0.0.0',
      :registry_port     => '9191',
      :log_file          => '/var/log/glance/api.log',
      :auth_type         => 'keystone',
      :auth_url          => 'http://127.0.0.1:5000/',
      :enabled           => true,
      :backlog           => '4096',
      :workers           => '7',
      :auth_host         => '127.0.0.1',
      :auth_port         => '35357',
      :auth_protocol     => 'http',
      :keystone_tenant   => 'admin',
      :keystone_user     => 'admin',
      :keystone_password => 'ChangeMe',
      :sql_idle_timeout  => '3600',
      :sql_connection    => 'sqlite:///var/lib/glance/glance.sqlite'
    }
  end

  [{:keystone_password => 'ChangeMe'},
   {
      :verbose           => 'true',
      :debug             => 'true',
      :bind_host         => '127.0.0.1',
      :bind_port         => '9222',
      :registry_host     => '127.0.0.1',
      :registry_port     => '9111',
      :log_file          => '/var/log/glance-api.log',
      :auth_type         => 'not_keystone',
      :auth_url          => 'http://192.168.56.210:5000/',
      :enabled           => false,
      :backlog           => '4095',
      :workers           => '5',
      :auth_host         => '127.0.0.2',
      :auth_port         => '35358',
      :auth_protocol     => 'https',
      :keystone_tenant   => 'admin2',
      :keystone_user     => 'admin2',
      :keystone_password => 'ChangeMe2',
      :sql_idle_timeout  => '36002',
      :sql_connection    => 'mysql:///var:lib@glance/glance'
    }
  ].each do |param_set|

    describe "when #{param_set == {:keystone_password => 'ChangeMe'} ? "using default" : "specifying"} class parameters" do

      let :param_hash do
        default_params.merge(param_set)
      end

      let :params do
        param_set
      end

      it { should contain_class 'glance' }

      it { should contain_service('glance-api').with(
        'ensure'     => param_hash[:enabled] ? 'running': 'stopped',
        'enable'     => param_hash[:enabled],
        'hasstatus'  => 'true',
        'hasrestart' => 'true'
      ) }

      it 'should lay down default api config' do
        [
          'verbose',
          'debug',
          'bind_host',
          'bind_port',
          'log_file',
          'registry_host',
          'registry_port'
        ].each do |config|
          should contain_glance_api_config("DEFAULT/#{config}").with_value(param_hash[config.intern])
        end
      end

      it 'should lay down default cache config' do
        [
          'verbose',
          'debug',
          'registry_host',
          'registry_port'
        ].each do |config|
          should contain_glance_cache_config("DEFAULT/#{config}").with_value(param_hash[config.intern])
        end
      end

      it 'should config db' do
        should contain_glance_api_config('DEFAULT/sql_connection').with_value(param_hash[:sql_connection])
        should contain_glance_api_config('DEFAULT/sql_idle_timeout').with_value(param_hash[:sql_idle_timeout])
      end

      it 'should lay down default auth config' do
        [
          'auth_host',
          'auth_port',
          'protocol',
          'auth_uri'
        ].each do |config|
          should contain_glance_api_config("keystone_authtoken/#{config}").with_value(param_hash[config.intern])
        end
      end

      it 'should configure itself for keystone if that is the auth_type' do
        if params[:auth_type] == 'keystone'
          should contain('paste_deploy/flavor').with_value('keystone+cachemanagement')
          ['admin_tenant_name', 'admin_user', 'admin_password'].each do |config|
            should contain_glance_api_config("keystone_authtoken/#{config}").with_value(param_hash[config.intern])
          end
          ['admin_tenant_name', 'admin_user', 'admin_password', 'auth_url'].each do |config|
            should contain_glance_cache_config("keystone_authtoken/#{config}").with_value(param_hash[config.intern])
          end
        end
      end
    end
  end
end
