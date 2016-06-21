require 'spec_helper'

describe 'fuel::astute' do
  shared_examples_for 'fuel::astute configuration' do
    context 'with defaults' do
      it 'install required packages' do
        [ 'psmisc',
          'python-editor',
          'nailgun-mcagents',
          'sysstat',
          'rubygem-amqp',
          'rubygem-amq-protocol',
          'rubygem-i18n',
          'rubygem-tzinfo',
          'rubygem-minitest',
          'rubygem-symboltable',
          'rubygem-thread_safe',
          'rubygem-astute' ].each do |pkg|
          should contain_package(pkg)
        end
      end

      it 'should configure astute.conf' do
        should contain_file('/etc/astute/astuted.conf')
      end

      it 'should configure log level as info' do
        should contain_file('/etc/sysconfig/astute').with_content(
          /loglevel info/
        )
      end
    end

    context 'with debugging enabled' do
      let (:params) do
        { :debug => true }
      end
      it 'should configure log level as debug' do
        should contain_file('/etc/sysconfig/astute').with_content(
          /loglevel debug/
        )
      end
    end

  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :operatingsystem => 'CentOS',
        :operatingsystemrelease => '7.2',
        :hostname => 'hostname.example.com' }
    end

    it_configures 'fuel::astute configuration'
  end
end
