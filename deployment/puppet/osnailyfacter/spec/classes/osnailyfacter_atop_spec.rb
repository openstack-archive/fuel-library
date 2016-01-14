require 'spec_helper'

describe 'osnailyfacter::atop' do

  shared_examples_for 'atop install and configure' do

    let :file_default_opts do
      {
        :ensure  => 'file',
        :owner   => 'root',
        :group   => 'root',
        :mode    => '0600',
      }
    end

    context "with default params" do
      it 'should setup with platform specific' do
        case facts[:osfamily]
        when 'Debian'
          conf_file    = '/etc/default/atop'
          acct_package = 'acct'
        when 'RedHat'
          conf_file    = '/etc/sysconfig/atop'
          acct_package = 'psacct'
        end

        is_expected.to contain_package(acct_package)

        is_expected.to contain_file(conf_file).with(
          file_default_opts.merge(:mode => '0644')
        )
      end

      it { is_expected.to contain_package('atop') }
      it { is_expected.to contain_service('atop') }

      it { is_expected.to contain_file('/etc/cron.daily/atop_retention').with(
        file_default_opts.merge(:mode => '0755')
      ) }

      it { is_expected.to contain_exec('initialize atop_current').with(
        :command     => '/etc/cron.daily/atop_retention',
        :refreshonly => true,
      ) }
    end

    context "with custom params" do
      let :params do
        {
          :custom_acct_file => '/tmp/atop.d/atop.acct',
        }
      end

      it { is_expected.to contain_file(File.dirname(params[:custom_acct_file])).with(
        file_default_opts.merge(:ensure => 'directory')
      ) }

      it { is_expected.to contain_file(params[:custom_acct_file]).with(
        file_default_opts
      ) }

      it { is_expected.to contain_exec('turns process accounting on').with(
        :command     => "accton #{params[:custom_acct_file]}",
        :refreshonly => true,
      ) }
    end

  end

  context 'on Debian platforms' do
    let :facts do
      {
        :osfamily        => 'Debian',
        :operatingsystem => 'Debian',
        :processorcount  => 2,
        :memorysize_mb   => 4096,
      }
    end

    it_configures 'atop install and configure'
  end

  context 'on RedHat platforms' do
    let :facts do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
        :processorcount  => 2,
        :memorysize_mb   => 4096,
      }
    end

    it_configures 'atop install and configure'
  end

end
