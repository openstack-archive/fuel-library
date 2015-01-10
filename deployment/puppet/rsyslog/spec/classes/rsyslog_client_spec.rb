require 'spec_helper'

describe 'rsyslog::client', :type => :class do

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
        let(:title) { 'rsyslog-client-basic' }

        it 'should compile' do
          should contain_file('/etc/rsyslog.d/client.conf')
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
        let(:title) { 'rsyslog-client-basic' }

        it 'should compile' do
          should contain_file('/etc/rsyslog.d/client.conf')
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
        let(:title) { 'rsyslog-client-basic' }

        it 'should compile' do
          should contain_file('/etc/syslog.d/client.conf')
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
        let(:title) { 'rsyslog-client-basic' }

        it 'should compile' do
          should contain_file('/etc/rsyslog.d/client.conf')
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
        let(:title) { 'rsyslog-client-basic' }

        it 'should compile' do
          should contain_file('/etc/rsyslog.d/client.conf')
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
        let(:title) { 'rsyslog-client-basic' }

        it 'should compile' do
          should contain_file('/etc/syslog.d/client.conf')
        end
      end
    end
  end

  context "Rsyslog version = nil" do
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
        let(:title) { 'rsyslog-client-basic' }

        it 'should compile' do
          should contain_file('/etc/rsyslog.d/client.conf')
        end
      end
    end
  end
end
