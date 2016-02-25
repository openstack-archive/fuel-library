require 'spec_helper'
require 'shared-examples'
manifest = 'master/nailgun-only.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :file
    MockFunction.new(:file) do |function|
      allow(function).to receive(:call).with(['/root/.ssh/id_rsa.pub']).and_return('key')
    end
  end

  shared_examples 'catalog' do

    context 'running on CentOS 6' do
      let(:facts) do
        Noop.centos_facts.merge({
          :operatingsystemmajrelease => '6'
        })
      end
      it 'configure nailgun supervisor' do
        should contain_class('nailgun::supervisor').with(
          :service_enabled => false,
          :nailgun_env     => '/usr',
          :ostf_env        => '/usr',
          :conf_file       => 'nailgun/supervisord.conf.nailgun.erb',
          :require         => 'Class[Nailgun::Venv]'
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

      it 'should disable supervisord service' do
        should contain_service('supervisord').with(
          :ensure     => false,
          :enable     => false,
          :require    => 'Package[supervisor]',
          :hasrestart => true,
          :restart    => '/usr/bin/supervisorctl stop all; /etc/init.d/supervisord restart',
        )
      end
    end

    context 'running on CentOS 7' do
      let(:facts) do
        Noop.centos_facts.merge({
          :operatingsystemmajrelease => '7'
        })
      end
      let(:params) { {
        :services => [ 'assassind',
                       'nailgun',
                       'oswl_flavor_collectord',
                       'oswl_image_collectord',
                       'oswl_keystone_user_collectord',
                       'oswl_tenant_collectord',
                       'oswl_vm_collectord',
                       'oswl_volume_collectord',
                       'receiverd',
                       'statsenderd' ]
      } }


      it 'configures service with valid params' do
        fuel_settings = Noop.puppet_function 'parseyaml',facts[:astute_settings_yaml]
        if fuel_settings['PRODUCTION']
          production = fuel_settings['PRODUCTION']
        else
          production = 'docker'
        end
        should contain_class('nailgun::systemd').with(
          :production => production,
          :services   => params[:services],
          :require    => 'Class[Nailgun::Venv]'
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
          should contain_file('/etc/nailgun/settings.yaml').that_notifies("Service[#{service}]")
        end
      end
    end # context
  end # catalog
  test_centos manifest
end
