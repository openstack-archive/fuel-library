require 'spec_helper'

describe 'docker' do

  let(:default_params) { {
    :package_ensure => 'latest',
    :admin_ipaddress => '10.20.0.2',
    :limit           => '102400',
    :docker_package  => 'docker-io',
    :docker_service  => 'docker',
    :docker_engine   => 'native',
  } }

  shared_examples_for 'docker configuration' do
    let :params do
      default_params
    end


    context 'with valid params' do
      let :params do
        default_params.merge!({
          :release => '8.0',
          :dependent_dirs => ["/var/log/docker-logs", "/var/log/docker-logs/remote",
              "/var/log/docker-logs/audit", "/var/log/docker-logs/cobbler",
              "/var/log/docker-logs/ConsoleKit", "/var/log/docker-logs/coredump",
              "/var/log/docker-logs/httpd", "/var/log/docker-logs/lxc",
              "/var/log/docker-logs/nailgun", "/var/log/docker-logs/naily",
              "/var/log/docker-logs/nginx", "/var/log/docker-logs/ntpstats",
              "/var/log/docker-logs/puppet", "/var/log/docker-logs/rabbitmq",
              "/var/log/docker-logs/supervisor",
              "/var/lib/fuel", "/var/lib/fuel/keys", "/var/lib/fuel/ibp",
              "/var/lib/fuel/container_data",
              "/var/lib/fuel/container_data/8.0",
              "/var/lib/fuel/container_data/8.0/cobbler",
              "/var/lib/fuel/container_data/8.0/postgres",
                  ]
        })
      end

      it 'configures with the valid params' do
        should contain_class('docker')
        should contain_package('lxc').with_ensure('installed')
        should contain_package(params[:docker_package]).with_ensure(params[:package_ensure])
        should contain_service(params[:docker_service]).with(
          :enable => true,
          :ensure => 'running',
          :hasrestart => true,
          :require => 'Package[docker-io]')
        should contain_file('/etc/sysconfig/docker')
        params[:dependent_dirs].each do |d|
          should contain_file(d).with(
            :ensure => 'directory',
            :owner  => 'root',
            :group  => 'root',
            :mode   => '0755')
        end
        should contain_exec('wait for docker-to-become-ready')
        should contain_exec('build docker containers')
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'docker configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'docker configuration'
  end

end

