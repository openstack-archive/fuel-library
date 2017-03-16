require "spec_helper"

describe "fuel::dsscheduler" do

  let :global_facts do
    {
      :processorcount => 42,
      :os_workers     => 8,
    }
  end

  shared_examples_for "distributed serialization" do

    context "with default params" do

      it "installs python-distributed" do
        is_expected.to contain_package('python-distributed').with(
          :ensure => 'installed',
        )
      end

      it "creates new user for serialization" do
        is_expected.to contain_user('serializer').with(
          :ensure => 'present',
          :name   => 'serializer',
          :gid    => 'serializer',
        )
      end

      it "creates new group for serialization" do
        is_expected.to contain_group('serializer').with(
          :ensure => 'present',
          :name   => 'serializer',
        )
      end

      it "start service for serialization" do
        is_expected.to contain_service('dsscheduler').with(
          :ensure  => 'true',
          :enabled => 'true',
        )
      end

      it "configures service for serialization" do
        is_expected.to contain_file('/etc/systemd/system/dsscheduler.service').with(
          :ensure  => 'present',
          :owner   => 'root',
          :group   => 'root',
          :mode    => '0664',
        )
      end

    end

  end

  context 'on RedHat platforms' do
    let :facts do
      @default_facts.merge({
        :osfamily               => 'RedHat',
        :operatingsystem        => 'CentOS',
        :operatingsystemrelease => '7.0',
        :puppetversion          => Puppet.version,
      })
    end
    it_configures "distributed serialization"
  end

end

