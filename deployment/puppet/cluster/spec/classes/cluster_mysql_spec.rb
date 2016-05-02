require 'spec_helper'

describe 'cluster::mysql' do
  let(:pre_condition) do
    'include ::mysql::server'
  end
  shared_examples_for 'cluster::mysql configuration' do
    context 'with valid params' do
      let :params do
        {
          :mysql_user => 'username',
          :mysql_password => 'password',
          :wsrecover_innodb_log_group_home_dir => '/var/tmp',
          :wsrecover_innodb_data_file_path => 'ibdata1:12M:autoextend ',
          :wsrecover_innodb_data_home_dir => '/var/tmp',
        }
      end

      it 'defines a creds file' do
        should contain_file('/etc/mysql/user.cnf').with_content(
          "[client]\nuser = #{params[:mysql_user]}\npassword = #{params[:mysql_password]}\n"
        )
      end

      it 'defines a wsrep recover conf file' do
        should contain_file('/etc/mysql/wsrecover.cnf').with_content(
          "[mysqld]\ninnodb-data-home-dir = #{params[:wsrecover_innodb_data_home_dir]}\n" +
          "innodb-log-group-home-dir = #{params[:wsrecover_innodb_log_group_home_dir]}\n" +
          "innodb-data-file-path = #{params[:wsrecover_innodb_data_file_path]}\n"
        )
      end

      it 'configures a cs_resource' do
        should contain_pcmk_resource('p_mysqld').with(
          :ensure => 'present',
          :parameters => {
            'config' => '/etc/mysql/my.cnf',
            'config_wsrecover' => '/etc/mysql/wsrecover.cnf',
            'test_conf' => '/etc/mysql/user.cnf',
            'socket' =>'/var/run/mysqld/mysqld.sock'
          }
        )
        should contain_pcmk_resource('p_mysqld').that_comes_before('Service[mysqld]')
      end

      it 'creates init-file with grants' do
        should contain_exec('create-init-file').with_command(
          /'username'@'%' IDENTIFIED BY 'password'/
        )
        should contain_exec('create-init-file').with_command(
          /'username'@'localhost' IDENTIFIED BY 'password'/
        )
        should contain_exec('create-init-file').that_comes_before('Service[mysqld]')
        should contain_exec('create-init-file').that_notifies('Exec[wait-initial-sync]')
      end

      it 'creates exec to remove init-file' do
        should contain_exec('rm-init-file')
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'cluster::mysql configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :operatingsystemmajrelease => '7',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'cluster::mysql configuration'
  end

end
