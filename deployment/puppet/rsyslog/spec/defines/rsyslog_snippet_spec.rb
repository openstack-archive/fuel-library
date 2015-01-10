require 'spec_helper'

describe 'rsyslog::snippet', :type => :define do

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
          :operatingsystem        => 'Redhat',
          :operatingsystemmajrelease => 6,
        })
      end

      let (:params) {
        {
          'content' => 'Random Content',
        }
      }

      context "default usage (osfamily = RedHat)" do
        let(:title) { 'rsyslog-snippet-basic' }

        it 'should compile' do
          should contain_file('/etc/rsyslog.d/rsyslog-snippet-basic.conf').with_content("# This file is managed by Puppet, changes may be overwritten\nRandom Content\n")
        end
      end
    end

    context "osfamily = Debian" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'Debian',
        })
      end

      let (:params) {
        {
          'content' => 'Random Content',
        }
      }

      context "default usage (osfamily = Debian)" do
        let(:title) { 'rsyslog-snippet-basic' }

        it 'should compile' do
          should contain_file('/etc/rsyslog.d/rsyslog-snippet-basic.conf').with_content("# This file is managed by Puppet, changes may be overwritten\nRandom Content\n")
        end
      end
    end

    context "osfamily = FreeBSD" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'freebsd',
        })
      end

      let (:params) {
        {
          'content' => 'Random Content',
        }
      }

      context "default usage (osfamily = Debian)" do
        let(:title) { 'rsyslog-snippet-basic' }

        it 'should compile' do
          should contain_file('/etc/syslog.d/rsyslog-snippet-basic.conf').with_content("# This file is managed by Puppet, changes may be overwritten\nRandom Content\n")
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
          :operatingsystem        => 'Redhat',
          :operatingsystemmajrelease => 6,
        })
      end

      let (:params) {
        {
          'content' => 'Random Content',
        }
      }

      context "default usage (osfamily = RedHat)" do
        let(:title) { 'rsyslog-snippet-basic' }

        it 'should compile' do
          should contain_file('/etc/rsyslog.d/rsyslog-snippet-basic.conf').with_content("# This file is managed by Puppet, changes may be overwritten\nRandom Content\n")
        end
      end
    end

    context "osfamily = Debian" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'Debian',
        })
      end

      let (:params) {
        {
          'content' => 'Random Content',
        }
      }

      context "default usage (osfamily = Debian)" do
        let(:title) { 'rsyslog-snippet-basic' }

        it 'should compile' do
          should contain_file('/etc/rsyslog.d/rsyslog-snippet-basic.conf').with_content("# This file is managed by Puppet, changes may be overwritten\nRandom Content\n")
        end
      end
    end

    context "osfamily = FreeBSD" do
      let :facts do
        default_facts.merge!({
          :osfamily        => 'freebsd',
        })
      end

      let (:params) {
        {
          'content' => 'Random Content',
        }
      }

      context "default usage (osfamily = Debian)" do
        let(:title) { 'rsyslog-snippet-basic' }

        it 'should compile' do
          should contain_file('/etc/syslog.d/rsyslog-snippet-basic.conf').with_content("# This file is managed by Puppet, changes may be overwritten\nRandom Content\n")
        end
      end
    end
  end

end
