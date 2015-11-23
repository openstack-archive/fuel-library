require 'spec_helper'
require 'shared-examples'
manifest = 'master/host-only.pp'

describe manifest do

  shared_examples 'catalog' do

    let(:params) { {
      containers => ['astute', 'cobbler', 'keystone', 'mcollective', 'nailgun',
    'nginx', 'ostf', 'postgres', 'rabbitmq', 'rsync', 'rsyslog']
    } }

    release = facts[:fuel_release]

    context 'running on centos 6' do
      let(:facts) do
        Noop.centos_facts.merge({
          :operatingsystemmajrelease == '6'
        })
      end
      it 'configure containers supervisor' do
        should contain_class('docker::supervisor').with({
          :release => release,
          :require => "File[/etc/supervisord.d/#{release}]",
        })
        params[:containers].each do |container|
          should contain_file("/etc/supervisord.d/#{release}/#{container}.conf").with({
            :owner => 'root',
            :group => 'root',
            :mode  => '0644'
          })
        end
      end #it do
    end #context

    context 'running on centos 7' do
      let(:facts) do
        Noop.centos_facts.merge({
          :operatingsystemmajrelease >= '7'
        })
      end

      it 'configure containers systemd' do
        should contain_class('docker::systemd').with({
          :release => release
        })
        params[:containers].each do |container|
          should contain_file("/usr/lib/systemd/system/docker-#{container}.service").with({
            :owner => 'root',
            :group => 'root',
            :mode  => '0644',
          })
          shoul contain_service("docker-#{container}").with({
            :ensure => 'undef',
            :enable => 'true',
          })
        end
      end #it do
    end #context
  end #shared_examples

  test_centos manifest
end
