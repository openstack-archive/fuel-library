require 'rspec-puppet'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
end

@oses = {

  'Debian' => {
    :operatingsystem        => 'Debian',
    :osfamily               => 'Debian',
    :operatingsystemrelease => '7.0',
    :lsbdistid              => 'Debian',
    :lsbdistrelease         => '7.0',
    :architecture           => 'amd64',

    :prefix_pamd            => '/etc/pam.d',
  },

  'Ubuntu' => {
    :operatingsystem        => 'Ubuntu',
    :osfamily               => 'Debian',
    :operatingsystemrelease => '13.04',
    :lsbdistid              => 'Ubuntu',
    :lsbdistrelease         => '13.04',
    :architecture           => 'amd64',

    :prefix_pamd            => '/etc/pam.d',
  },

  'Redhat 5' => {
    :operatingsystem            => 'Redhat',
    :osfamily                   => 'Redhat',
    :operatingsystemrelease     => '5.0',
    :operatingsystemmajrelease  => '5',
    :lsbdistid                  => 'Redhat',
    :lsbdistrelease             => '5.0',
    :architecture               => 'x86_64',

    :prefix_pamd            => '/etc/pam.d',
    :cfg_system_auth        => '/etc/pam.d/system-auth',
    :cfg_system_auth_ac     => '/etc/pam.d/system-auth-ac',
  },

  'Redhat 6' => {
    :operatingsystem            => 'Redhat',
    :osfamily                   => 'Redhat',
    :operatingsystemrelease     => '6.0',
    :operatingsystemmajrelease  => '6',
    :lsbdistid                  => 'Redhat',
    :lsbdistrelease             => '6.0',
    :architecture               => 'x86_64',

    :prefix_pamd            => '/etc/pam.d',
    :cfg_system_auth        => '/etc/pam.d/system-auth',
    :cfg_system_auth_ac     => '/etc/pam.d/system-auth-ac',
    :cfg_password_auth      => '/etc/pam.d/password-auth',
    :cfg_password_auth_ac   => '/etc/pam.d/password-auth-ac',
  },

  'CentOS 5' => {
    :operatingsystem            => 'CentOS',
    :osfamily                   => 'Redhat',
    :operatingsystemrelease     => '5.0',
    :operatingsystemmajrelease  => '5',
    :lsbdistid                  => 'CentOS',
    :lsbdistrelease             => '5.0',
    :architecture               => 'x86_64',

    :prefix_pamd            => '/etc/pam.d',
    :cfg_system_auth        => '/etc/pam.d/system-auth',
    :cfg_system_auth_ac     => '/etc/pam.d/system-auth-ac',
  },

  'CentOS 6' => {
    :operatingsystem            => 'CentOS',
    :osfamily                   => 'Redhat',
    :operatingsystemrelease     => '6.0',
    :operatingsystemmajrelease  => '6',
    :lsbdistid                  => 'CentOS',
    :lsbdistrelease             => '6.0',
    :architecture               => 'x86_64',

    :prefix_pamd            => '/etc/pam.d',
    :cfg_system_auth        => '/etc/pam.d/system-auth',
    :cfg_system_auth_ac     => '/etc/pam.d/system-auth-ac',
    :cfg_password_auth      => '/etc/pam.d/password-auth',
    :cfg_password_auth_ac   => '/etc/pam.d/password-auth-ac',
  },

  'Scientific Linux 6' => {
    :operatingsystem            => 'Scientific',
    :osfamily                   => 'Redhat',
    :operatingsystemrelease     => '6.0',
    :operatingsystemmajrelease  => '6',
    :lsbdistid                  => 'Scientific',
    :lsbdistrelease             => '6.0',
    :architecture               => 'x86_64',

    :prefix_pamd            => '/etc/pam.d',
    :cfg_system_auth        => '/etc/pam.d/system-auth',
    :cfg_system_auth_ac     => '/etc/pam.d/system-auth-ac',
    :cfg_password_auth      => '/etc/pam.d/password-auth',
    :cfg_password_auth_ac   => '/etc/pam.d/password-auth-ac',
  },

}


