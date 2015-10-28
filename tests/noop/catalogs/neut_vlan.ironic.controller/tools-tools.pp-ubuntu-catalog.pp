anchor { 'ssh::server::end':
  name => 'ssh::server::end',
}

anchor { 'ssh::server::start':
  before => 'Class[Ssh::Server::Install]',
  name   => 'ssh::server::start',
}

apt::conf { 'notranslations':
  ensure        => 'present',
  content       => 'Acquire::Languages "none";',
  name          => 'notranslations',
  notify_update => 'false',
  priority      => '50',
}

apt::setting { 'conf-notranslations':
  ensure        => 'present',
  content       => '// This file is managed by Puppet. DO NOT EDIT.
Acquire::Languages "none";',
  name          => 'conf-notranslations',
  notify_update => 'false',
  priority      => '50',
}

class { 'Apt::Params':
  name => 'Apt::Params',
}

class { 'Concat::Setup':
  name => 'Concat::Setup',
}

class { 'Osnailyfacter::Acpid':
  name            => 'Osnailyfacter::Acpid',
  service_enabled => 'true',
  service_state   => 'running',
}

class { 'Osnailyfacter::Atop':
  interval        => '20',
  logpath         => '/var/log/atop',
  name            => 'Osnailyfacter::Atop',
  rotate          => '7',
  service_enabled => 'true',
  service_state   => 'running',
}

class { 'Osnailyfacter::Ssh':
  ciphers       => 'aes256-ctr,aes192-ctr,aes128-ctr,arcfour256,arcfour128',
  log_lvl       => 'VERBOSE',
  macs          => 'hmac-sha2-512,hmac-sha2-256,hmac-ripemd160,hmac-sha1',
  name          => 'Osnailyfacter::Ssh',
  password_auth => 'no',
  ports         => '22',
  protocol_ver  => '2',
}

class { 'Puppet::Pull':
  manifests_source => 'rsync://10.109.37.2:/puppet/2015.1.0-8.0/manifests/',
  modules_source   => 'rsync://10.109.37.2:/puppet/2015.1.0-8.0/modules/',
  name             => 'Puppet::Pull',
  script           => '/usr/local/bin/puppet-pull',
  template         => 'puppet/puppet-pull.sh.erb',
}

class { 'Settings':
  name => 'Settings',
}

class { 'Ssh::Params':
  name => 'Ssh::Params',
}

class { 'Ssh::Server::Config':
  name   => 'Ssh::Server::Config',
  notify => 'Class[Ssh::Server::Service]',
}

class { 'Ssh::Server::Install':
  before => 'Class[Ssh::Server::Config]',
  name   => 'Ssh::Server::Install',
}

class { 'Ssh::Server::Service':
  before => 'Anchor[ssh::server::end]',
  name   => 'Ssh::Server::Service',
}

class { 'Ssh::Server':
  ensure               => 'present',
  name                 => 'Ssh::Server',
  options              => {'AllowTcpForwarding' => 'yes', 'ChallengeResponseAuthentication' => 'no', 'Ciphers' => 'aes256-ctr,aes192-ctr,aes128-ctr,arcfour256,arcfour128', 'GSSAPIAuthentication' => 'no', 'LogLevel' => 'VERBOSE', 'MACs' => 'hmac-sha2-512,hmac-sha2-256,hmac-ripemd160,hmac-sha1', 'PasswordAuthentication' => 'no', 'Port' => '22', 'Protocol' => '2', 'PubkeyAuthentication' => 'yes', 'RSAAuthentication' => 'yes', 'StrictModes' => 'yes', 'Subsystem' => 'sftp /usr/lib/openssh/sftp-server', 'UseDNS' => 'no', 'UsePAM' => 'yes', 'UsePrivilegeSeparation' => 'yes', 'X11Forwarding' => 'no'},
  storeconfigs_enabled => 'false',
}

class { 'main':
  name => 'main',
}

concat::fragment { 'global config':
  content => '# File is managed by Puppet
Port 22

AcceptEnv LANG LC_*
AllowTcpForwarding yes
ChallengeResponseAuthentication no
Ciphers aes256-ctr,aes192-ctr,aes128-ctr,arcfour256,arcfour128
GSSAPIAuthentication no
LogLevel VERBOSE
MACs hmac-sha2-512,hmac-sha2-256,hmac-ripemd160,hmac-sha1
PasswordAuthentication no
PrintMotd no
Protocol 2
PubkeyAuthentication yes
RSAAuthentication yes
StrictModes yes
Subsystem sftp /usr/lib/openssh/sftp-server
UseDNS no
UsePAM yes
UsePrivilegeSeparation yes
X11Forwarding no
',
  name    => 'global config',
  order   => '00',
  target  => '/etc/ssh/sshd_config',
}

concat { '/etc/ssh/sshd_config':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => '0',
  mode           => '0600',
  name           => '/etc/ssh/sshd_config',
  notify         => 'Service[ssh]',
  order          => 'alpha',
  owner          => '0',
  path           => '/etc/ssh/sshd_config',
  replace        => 'true',
  warn           => 'false',
}

exec { 'concat_/etc/ssh/sshd_config':
  alias     => 'concat_/tmp//_etc_ssh_sshd_config',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_ssh_sshd_config/fragments.concat.out" -d "/tmp//_etc_ssh_sshd_config"',
  notify    => 'File[/etc/ssh/sshd_config]',
  require   => ['File[/tmp//_etc_ssh_sshd_config]', 'File[/tmp//_etc_ssh_sshd_config/fragments]', 'File[/tmp//_etc_ssh_sshd_config/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_ssh_sshd_config]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_ssh_sshd_config/fragments.concat.out" -d "/tmp//_etc_ssh_sshd_config" -t',
}

exec { 'host-ssh-keygen':
  command => 'ssh-keygen -A',
  path    => ['/bin', '/usr/bin'],
  require => 'Class[Ssh::Server]',
}

exec { 'ln -s /var/log/atop/atop_current':
  command => 'ln -s /var/log/atop/atop_$(date +%Y%m%d) /var/log/atop/atop_current',
  path    => ['/bin', '/usr/bin'],
  require => 'Service[atop]',
  unless  => 'test -L /var/log/atop/atop_current',
}

file { '/etc/apt/apt.conf.d/50notranslations':
  ensure  => 'present',
  content => '// This file is managed by Puppet. DO NOT EDIT.
Acquire::Languages "none";',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/apt/apt.conf.d/50notranslations',
}

file { '/etc/cron.daily/atop_retention':
  content => '#!/bin/bash
# Managed by puppet
# This file manages the atop binary files. It will keep binary files for last
# 7 days instead of 30 days provided by atop.
PATH=/sbin:/bin:/usr/sbin:/usr/bin

# remove files older than 7 days
find /var/log/atop -type f -name 'atop_*' -mtime +7 -delete

# link current to todays file
ln -f -s /var/log/atop/atop_$(date +%Y%m%d) /var/log/atop/atop_current
',
  group   => 'root',
  mode    => '0755',
  owner   => 'root',
  path    => '/etc/cron.daily/atop_retention',
}

file { '/etc/default/atop':
  ensure  => 'present',
  content => '# Managed by puppet
#

INTERVAL=20
LOGPATH="/var/log/atop"
OUTFILE="$LOGPATH/daily.log"
',
  notify  => 'Service[atop]',
  path    => '/etc/default/atop',
}

file { '/etc/ssh/sshd_config':
  ensure  => 'present',
  alias   => 'concat_/etc/ssh/sshd_config',
  backup  => 'puppet',
  group   => '0',
  mode    => '0600',
  owner   => '0',
  path    => '/etc/ssh/sshd_config',
  replace => 'true',
  source  => '/tmp//_etc_ssh_sshd_config/fragments.concat.out',
}

file { '/tmp//_etc_ssh_sshd_config/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_ssh_sshd_config/fragments.concat.out',
}

file { '/tmp//_etc_ssh_sshd_config/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_ssh_sshd_config/fragments.concat',
}

file { '/tmp//_etc_ssh_sshd_config/fragments/00_global config':
  ensure  => 'file',
  alias   => 'concat_fragment_global config',
  backup  => 'puppet',
  content => '# File is managed by Puppet
Port 22

AcceptEnv LANG LC_*
AllowTcpForwarding yes
ChallengeResponseAuthentication no
Ciphers aes256-ctr,aes192-ctr,aes128-ctr,arcfour256,arcfour128
GSSAPIAuthentication no
LogLevel VERBOSE
MACs hmac-sha2-512,hmac-sha2-256,hmac-ripemd160,hmac-sha1
PasswordAuthentication no
PrintMotd no
Protocol 2
PubkeyAuthentication yes
RSAAuthentication yes
StrictModes yes
Subsystem sftp /usr/lib/openssh/sftp-server
UseDNS no
UsePAM yes
UsePrivilegeSeparation yes
X11Forwarding no
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/ssh/sshd_config]',
  path    => '/tmp//_etc_ssh_sshd_config/fragments/00_global config',
  replace => 'true',
}

file { '/tmp//_etc_ssh_sshd_config/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/ssh/sshd_config]',
  path    => '/tmp//_etc_ssh_sshd_config/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_ssh_sshd_config':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_ssh_sshd_config',
}

file { '/tmp//bin/concatfragments.rb':
  ensure => 'file',
  backup => 'puppet',
  mode   => '0755',
  path   => '/tmp//bin/concatfragments.rb',
  source => 'puppet:///modules/concat/concatfragments.rb',
}

file { '/tmp//bin':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0755',
  path   => '/tmp//bin',
}

file { '/tmp/':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0755',
  path   => '/tmp',
}

file { '/usr/local/bin/puppet-pull':
  ensure  => 'present',
  content => '#!/bin/sh
local_modules="/etc/puppet/modules"
local_manifests="/etc/puppet/manifests"
remote_modules="rsync://10.109.37.2:/puppet/2015.1.0-8.0/modules/"
remote_manifests="rsync://10.109.37.2:/puppet/2015.1.0-8.0/manifests/"
main_manifest="/etc/puppet/manifests/site.pp"

rsync -rvc --delete "${remote_modules}/" "${local_modules}/"
rsync -rvc --delete "${remote_manifests}/" "${local_manifests}/"
',
  group   => 'root',
  mode    => '0755',
  owner   => 'root',
  path    => '/usr/local/bin/puppet-pull',
}

package { 'acpid':
  ensure => 'installed',
  before => 'Service[acpid]',
  name   => 'acpid',
}

package { 'atop':
  ensure => 'installed',
  before => 'File[/etc/default/atop]',
  name   => 'atop',
}

package { 'cloud-init':
  ensure => 'absent',
  name   => 'cloud-init',
}

package { 'fuel-misc':
  ensure => 'present',
  name   => 'fuel-misc',
}

package { 'htop':
  ensure => 'present',
  name   => 'htop',
}

package { 'man':
  ensure => 'present',
  name   => 'man',
}

package { 'openssh-server':
  ensure => 'present',
  name   => 'openssh-server',
}

package { 'screen':
  ensure => 'present',
  name   => 'screen',
}

package { 'strace':
  ensure => 'present',
  name   => 'strace',
}

package { 'tcpdump':
  ensure => 'present',
  name   => 'tcpdump',
}

package { 'tmux':
  ensure => 'present',
  name   => 'tmux',
}

service { 'acpid':
  ensure => 'running',
  enable => 'true',
  name   => 'acpid',
}

service { 'atop':
  ensure => 'running',
  enable => 'true',
  name   => 'atop',
  notify => 'Exec[ln -s /var/log/atop/atop_current]',
}

service { 'ssh':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'ssh',
  require    => 'Class[Ssh::Server::Config]',
}

stage { 'main':
  name => 'main',
}

