require 'spec_helper'
require 'shared-examples'
manifest = 'master/astute-only.pp'

# HIERA: master
# FACTS: master_centos6 master_centos7

describe manifest do
  shared_examples 'catalog' do
    context 'running on CentOS 6' do
      let(:facts) do
        task.facts_data.merge({
          :operatingsystemmajrelease => '6'
        })
      end
      it 'configure nailgun supervisor' do
        fuel_settings = task.puppet_function 'parseyaml',facts[:astute_settings_yaml]
        production = task.puppet_function 'pick',fuel_settings['PRODUCTION'],'docker'
        if production== 'prod'
        env_path = '/usr'
        else
          env_path = '/opt/nailgun'
        end
        should contain_class('nailgun::supervisor').with(
          :nailgun_env     => env_path,
          :ostf_env        => env_path,
          :conf_file       => 'nailgun/supervisord.conf.astute.erb',
          :require         => 'Class[Nailgun::Astute]'
        )
      end

      it 'should prepare supervisord configuration file' do
        should contain_file('/etc/supervisord.conf').with(
          :owner   => 'root',
          :group   => 'root',
          :mode    => '0644',
          :require => 'Package[supervisor]',
          :notify  => 'Service[supervisord]',
        )
      end

      it 'should enable supervisord service' do
        should contain_service('supervisord').with(
          :ensure     => true,
          :enable     => true,
          :require    => 'Package[supervisor]',
          :hasrestart => true,
          :restart    => '/usr/bin/supervisorctl stop all; /etc/init.d/supervisord restart',
        )
      end
    end

    context 'running on CentOS 7' do
      let(:facts) do
        task.facts_data.merge({
          :operatingsystemmajrelease => '7'
        })
      end
      let(:params) { { :services => [ 'astute' ] } }

      it 'configures service with valid params' do
        fuel_settings = task.puppet_function 'parseyaml',facts[:astute_settings_yaml]
        production = task.puppet_function 'pick',fuel_settings['PRODUCTION'],'docker'
        should contain_class('nailgun::systemd').with(
          :production => production,
          :services   => params[:services],
          :require    => 'Class[Nailgun::Astute]'
        )
        params[:services].each do |service|
          should contain_file("/etc/systemd/system/#{service}.service.d/fuel.conf").with({
            :mode  => '0644',
            :owner => 'root',
            :group => 'root',
          })
          should contain_service(service).with({
            :ensure    => 'running',
            :enable    => 'true',
          })
        end
      end

      it {
        should contain_file('/etc/astute/astuted.conf').with({
            :mode    => '0644',
            :owner   => 'root',
            :group   => 'root',
            :require => 'File[/etc/astute]'
        }).that_notifies('Service[astute]')
      }
    end

  end
  test_centos manifest
end

