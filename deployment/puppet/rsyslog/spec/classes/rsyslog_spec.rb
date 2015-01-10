require 'spec_helper'

describe 'rsyslog', :type => :class do

  context "Rsyslog version >= 8" do
    let(:default_facts) do
      {
        :rsyslog_version => '8.1.2'
      }
    end

    context "osfamily = RedHat" do
      let :facts do
        default_facts.merge!({
          :osfamily               => 'RedHat',
          :operatingsystem        => 'RedHat',
          :operatingsystemmajrelease => 6,
        })
      end

      context "default usage (osfamily = RedHat)" do
        let(:title) { 'rsyslog-basic' }

        it 'should compile' do
          should contain_class('rsyslog::install')
          should contain_class('rsyslog::config')
          should contain_class('rsyslog::service')
        end
      end
    end

    context "osfamily = Debian" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'Debian',
        })
      end

      context "default usage (osfamily = Debian)" do
        let(:title) { 'rsyslog-basic' }

        it 'should compile' do
          should contain_class('rsyslog::install')
          should contain_class('rsyslog::config')
          should contain_class('rsyslog::service')
        end
      end
    end

    context "osfamily = FreeBSD" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'freebsd',
        })
      end

      context "default usage (osfamily = FreeBSD)" do
        let(:title) { 'rsyslog-basic' }

        it 'should compile' do
          should contain_class('rsyslog::install')
          should contain_class('rsyslog::config')
          should contain_class('rsyslog::service')
        end
      end
    end

    context "osfamily = RedHat" do
      let :facts do
        default_facts.merge!({
          :osfamily               => 'RedHat',
          :operatingsystem        => 'RedHat',
          :operatingsystemmajrelease => 6,
        })
      end

      context "default usage (osfamily = RedHat)" do
        let(:title) { 'rsyslog-basic' }

        it 'should compile' do
          should contain_file('/etc/rsyslog.conf')
          should contain_file('/etc/rsyslog.d/')
        end
      end
    end

    context "osfamily = Debian" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'Debian',
        })
      end

      context "default usage (osfamily = Debian)" do
        let(:title) { 'rsyslog-basic' }

        it 'should compile' do
          should contain_file('/etc/rsyslog.conf')
          should contain_file('/etc/rsyslog.d/')
        end
      end
    end

    context "osfamily = FreeBSD" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'freebsd',
        })
      end

      context "default usage (osfamily = Debian)" do
        let(:title) { 'rsyslog-basic' }

        it 'should compile' do
          should contain_file('/etc/syslog.conf')
          should contain_file('/etc/syslog.d/')
        end
      end
    end

    context "osfamily = RedHat" do
      let :facts do
        default_facts.merge!({
          :osfamily               => 'RedHat',
          :operatingsystem        => 'RedHat',
          :operatingsystemmajrelease => 6,
        })
      end

      context "default usage (osfamily = RedHat)" do
        let(:title) { 'rsyslog-install-basic' }

        it 'should compile' do
          should contain_package('rsyslog')
          should contain_package('rsyslog-relp')
        end
      end
    end

    context "osfamily = Debian" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'Debian',
        })
      end

      context "default usage (osfamily = Debian)" do
        let(:title) { 'rsyslog-install-basic' }

        it 'should compile' do
          should contain_package('rsyslog')
          should contain_package('rsyslog-relp')
        end
      end
    end

    context "osfamily = FreeBSD" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'freebsd',
        })
      end

      context "default usage (osfamily = Debian)" do
        let(:title) { 'rsyslog-install-basic' }

        it 'should compile' do
          should contain_package('sysutils/rsyslog5')
          should contain_package('sysutils/rsyslog5-relp')
        end
      end
    end

    context "osfamily = RedHat" do
      let :facts do
        default_facts.merge!({
          :osfamily               => 'RedHat',
          :operatingsystem        => 'RedHat',
          :operatingsystemmajrelease => 6,
        })
      end

      context "default usage (osfamily = RedHat)" do
        let(:title) { 'rsyslog-service-basic' }

        it 'should compile' do
          should contain_service('rsyslog')
        end
      end
    end

    context "osfamily = Debian" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'Debian',
        })
      end

      context "default usage (osfamily = Debian)" do
        let(:title) { 'rsyslog-service-basic' }

        it 'should compile' do
          should contain_service('rsyslog')
        end
      end
    end

    context "osfamily = FreeBSD" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'freebsd',
        })
      end

      context "default usage (osfamily = Debian)" do
        let(:title) { 'rsyslog-service-basic' }

        it 'should compile' do
          should contain_service('syslogd')
        end
      end
    end
  end

  context "Rsyslog version =< 8" do
    let(:default_facts) do
      {
        :rsyslog_version => '7.1.2'
      }
    end

    context "osfamily = RedHat" do
      let :facts do
        default_facts.merge!({
          :osfamily               => 'RedHat',
          :operatingsystem        => 'RedHat',
          :operatingsystemmajrelease => 6,
        })
      end

      context "default usage (osfamily = RedHat)" do
        let(:title) { 'rsyslog-basic' }

        it 'should compile' do
          should contain_class('rsyslog::install')
          should contain_class('rsyslog::config')
          should contain_class('rsyslog::service')
        end
      end
    end

    context "osfamily = Debian" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'Debian',
        })
      end

      context "default usage (osfamily = Debian)" do
        let(:title) { 'rsyslog-basic' }

        it 'should compile' do
          should contain_class('rsyslog::install')
          should contain_class('rsyslog::config')
          should contain_class('rsyslog::service')
        end
      end
    end

    context "osfamily = FreeBSD" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'freebsd',
        })
      end

      context "default usage (osfamily = FreeBSD)" do
        let(:title) { 'rsyslog-basic' }

        it 'should compile' do
          should contain_class('rsyslog::install')
          should contain_class('rsyslog::config')
          should contain_class('rsyslog::service')
        end
      end
    end

    context "osfamily = RedHat" do
      let :facts do
        default_facts.merge!({
          :osfamily               => 'RedHat',
          :operatingsystem        => 'RedHat',
          :operatingsystemmajrelease => 6,
        })
      end

      context "default usage (osfamily = RedHat)" do
        let(:title) { 'rsyslog-basic' }

        it 'should compile' do
          should contain_file('/etc/rsyslog.conf')
          should contain_file('/etc/rsyslog.d/')
        end
      end
    end

    context "osfamily = Debian" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'Debian',
        })
      end

      context "default usage (osfamily = Debian)" do
        let(:title) { 'rsyslog-basic' }

        it 'should compile' do
          should contain_file('/etc/rsyslog.conf')
          should contain_file('/etc/rsyslog.d/')
        end
      end
    end

    context "osfamily = FreeBSD" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'freebsd',
        })
      end

      context "default usage (osfamily = Debian)" do
        let(:title) { 'rsyslog-basic' }

        it 'should compile' do
          should contain_file('/etc/syslog.conf')
          should contain_file('/etc/syslog.d/')
        end
      end
    end

    context "osfamily = RedHat" do
      let :facts do
        default_facts.merge!({
          :osfamily               => 'RedHat',
          :operatingsystem        => 'RedHat',
          :operatingsystemmajrelease => 6,
        })
      end

      context "default usage (osfamily = RedHat)" do
        let(:title) { 'rsyslog-install-basic' }

        it 'should compile' do
          should contain_package('rsyslog')
          should contain_package('rsyslog-relp')
        end
      end
    end

    context "osfamily = Debian" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'Debian',
        })
      end

      context "default usage (osfamily = Debian)" do
        let(:title) { 'rsyslog-install-basic' }

        it 'should compile' do
          should contain_package('rsyslog')
          should contain_package('rsyslog-relp')
        end
      end
    end

    context "osfamily = FreeBSD" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'freebsd',
        })
      end

      context "default usage (osfamily = Debian)" do
        let(:title) { 'rsyslog-install-basic' }

        it 'should compile' do
          should contain_package('sysutils/rsyslog5')
          should contain_package('sysutils/rsyslog5-relp')
        end
      end
    end

    context "osfamily = RedHat" do
      let :facts do
        default_facts.merge!({
          :osfamily               => 'RedHat',
          :operatingsystem        => 'RedHat',
          :operatingsystemmajrelease => 6,
        })
      end

      context "default usage (osfamily = RedHat)" do
        let(:title) { 'rsyslog-service-basic' }

        it 'should compile' do
          should contain_service('rsyslog')
        end
      end
    end

    context "osfamily = Debian" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'Debian',
        })
      end

      context "default usage (osfamily = Debian)" do
        let(:title) { 'rsyslog-service-basic' }

        it 'should compile' do
          should contain_service('rsyslog')
        end
      end
    end

    context "osfamily = FreeBSD" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'freebsd',
        })
      end

      context "default usage (osfamily = Debian)" do
        let(:title) { 'rsyslog-service-basic' }

        it 'should compile' do
          should contain_service('syslogd')
        end
      end
    end
  end

  context "Rsyslog version >= 8" do
    let(:default_facts) do
      {
        :rsyslog_version => nil
      }
    end

    context "osfamily = RedHat" do
      let :facts do
        default_facts.merge!({
          :osfamily               => 'RedHat',
          :operatingsystem        => 'RedHat',
          :operatingsystemmajrelease => 6,
        })
      end

      context "default usage (osfamily = RedHat)" do
        it 'should compile' do
          should contain_file('/etc/rsyslog.conf')
          should contain_file('/etc/rsyslog.d/')
        end
      end
    end
  end
end
