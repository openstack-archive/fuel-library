require 'spec_helper'

describe 'nova::rabbitmq' do

  let :facts do
    {
      :puppetversion => '2.7',
      :osfamily => 'Debian',
      :lsbdistid => 'Debian',
    }
  end

  describe 'with defaults' do

    it 'should contain all of the default resources' do

      should contain_class('rabbitmq::server').with(
        :service_ensure    => 'running',
        :port              => '5672',
        :delete_guest_user => false
      )

      should contain_rabbitmq_vhost('/').with(
        :provider => 'rabbitmqctl'
      )
    end

  end

  describe 'with defaults and rabbitmq >1.0 <4.0 module' do
    let :params do
      {
        :rabbitmq_module   => '3.0'
      }
    end

    it 'should use ::rabbitmq and contain all of the default resources' do

      should contain_class('rabbitmq::server').with(
        :service_ensure    => 'running',
        :port              => '5672',
        :delete_guest_user => false
      )

      should contain_rabbitmq_vhost('/').with(
        :provider => 'rabbitmqctl'
      )
    end

  end

  describe 'with defaults and rabbitmq class set to rabbitmq::server' do
    let :params do
      {
        :rabbitmq_class   => 'rabbitmq::server'
      }
    end

    it 'should contain all of the default resources' do

      should contain_class('rabbitmq::server').with(
        :service_ensure    => 'running',
        :port              => '5672',
        :delete_guest_user => false
      )

      should contain_rabbitmq_vhost('/').with(
        :provider => 'rabbitmqctl'
      )
    end

  end

  describe 'with defaults and rabbitmq class set to ::rabbitmq' do
    let :params do
      {
        :rabbitmq_class   => '::rabbitmq'
      }
    end

    it 'should contain all of the default resources' do

      should contain_class('rabbitmq').with(
        :package_gpg_key         => 'http://www.rabbitmq.com/rabbitmq-signing-key-public.asc',
        :key_content             => false,
        :service_ensure          => 'running',
        :service_manage          => 'true',
        :port                    => '5672',
        :delete_guest_user       => false,
        :default_user            => 'guest',
        :default_pass            => 'guest',
        :config_cluster          => false,
        :version                 => '3.3.0',
        :node_ip_address         => 'UNSET',
        :config_kernel_variables => {},
        :config_variables        => {},
        :environment_variables   => {},
      )

      should contain_rabbitmq_vhost('/').with(
        :provider => 'rabbitmqctl'
      )
    end

  end


  describe 'with defaults and rabbitmq >=4.0 module' do
    let :params do
      {
        :rabbitmq_module   => '4.0'
      }
    end

    it 'should use ::rabbitmq and contain all of the default resources' do

      should contain_class('rabbitmq').with(
        :package_gpg_key         => 'http://www.rabbitmq.com/rabbitmq-signing-key-public.asc',
        :key_content             => false,
        :service_ensure          => 'running',
        :service_manage          => 'true',
        :port                    => '5672',
        :delete_guest_user       => false,
        :default_user            => 'guest',
        :default_pass            => 'guest',
        :config_cluster          => false,
        :version                 => '3.3.0',
        :node_ip_address         => 'UNSET',
        :config_kernel_variables => {},
        :config_variables        => {},
        :environment_variables   => {},
      )

      should contain_rabbitmq_vhost('/').with(
        :provider => 'rabbitmqctl'
      )
    end

  end

  describe 'when a rabbitmq user is specified' do

    let :params do
      {
        :userid   => 'dan',
        :password => 'pass'
      }
    end

    it 'should contain user and permissions' do

      should contain_rabbitmq_user('dan').with(
        :admin    => true,
        :password => 'pass',
        :provider => 'rabbitmqctl'
      )

      should contain_rabbitmq_user_permissions('dan@/').with(
        :configure_permission => '.*',
        :write_permission     => '.*',
        :read_permission      => '.*',
        :provider             => 'rabbitmqctl'
      )

    end

  end

  describe 'when disabled' do
    let :params do
      {
        :userid   => 'dan',
        :password => 'pass',
        :enabled  => false
      }
    end

    it 'should be disabled' do

      should_not contain_rabbitmq_user('dan')
      should_not contain_rabbitmq_user_permissions('dan@/')
      should contain_class('rabbitmq::server').with(
        :service_ensure    => 'stopped',
        :port              => '5672',
        :delete_guest_user => false
      )

      should_not contain_rabbitmq_vhost('/')

    end
  end

  describe 'with clustering' do

    let :params do
      {
        :cluster_disk_nodes => ['rabbit01', 'rabbit02', 'rabbit03']
      }
    end

    it 'should contain all the clustering resources' do

      should contain_class('rabbitmq::server').with(
        :service_ensure           => 'running',
        :port                     => '5672',
        :delete_guest_user        => false,
        :config_cluster           => true,
        :cluster_disk_nodes       => ['rabbit01', 'rabbit02', 'rabbit03'],
        :wipe_db_on_cookie_change => true
      )

    end

  end

  describe 'with clustering and new rabbitmq >=4.0 module' do

    let :params do
      {
        :rabbitmq_module    => '4.0',
        :cluster_disk_nodes => ['rabbit01', 'rabbit02', 'rabbit03'],
        :userid             => 'foo',
        :password           => 'bar'
      }
    end

    it 'should use ::rabbitmq and contain all the clustering resources' do

      should contain_class('rabbitmq').with(
        :package_gpg_key            => 'http://www.rabbitmq.com/rabbitmq-signing-key-public.asc',
        :key_content                => false,
        :service_ensure             => 'running',
        :service_manage             => 'true',
        :port                       => '5672',
        :delete_guest_user          => false,
        :default_user               => 'foo',
        :default_pass               => 'bar',
        :config_cluster             => true,
        :version                    => '3.3.0',
        :node_ip_address            => 'UNSET',
        :config_kernel_variables    => {},
        :config_variables           => {},
        :environment_variables      => {},
        :cluster_disk_nodes         => ['rabbit01', 'rabbit02', 'rabbit03'],
        :wipe_db_on_cookie_change   => true,
        :cluster_partition_handling => 'ignore',
      )

    end

  end

end
