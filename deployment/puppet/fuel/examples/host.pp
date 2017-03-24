notice('MODULAR: host.pp')

Exec  { path => '/usr/bin:/bin:/usr/sbin:/sbin' }

$fuel_settings = parseyaml($astute_settings_yaml)

#Purge empty NTP server entries
$ntp_servers = delete(delete_undef_values([$::fuel_settings['NTP1'],
  $::fuel_settings['NTP2'], $::fuel_settings['NTP3']]), '')

# Vars for File['/etc/dhcp/dhclient.conf']
$cobbler_host = $::fuel_settings['ADMIN_NETWORK']['ipaddress']

# Vars for File['/etc/fuel-utils/config']
$admin_ip = $::fuel_settings['ADMIN_NETWORK']['ipaddress']

# Vars for File['/etc/fuel/free_disk_check.yaml']
$monitord_user = $::fuel_settings['keystone']['monitord_user']
$monitord_password = $::fuel_settings['keystone']['monitord_password']
$monitord_tenant = 'services'

ensure_packages(['sudo', 'ami-creator', 'python-daemon', 'httpd',
                'iptables', 'crontabs', 'cronie-anacron',
                'rsyslog', 'rsync', 'screen', 'acpid',
                'fuel-migrate', 'dhcp', 'yum-plugin-priorities',
                'fuel-notify', 'rubygem-inifile'])

Class['openstack::logrotate'] ->
Class['fuel::bootstrap_cli']

fuel::sshkeygen { '/root/.ssh/id_rsa':
  homedir   => '/root',
  username  => 'root',
  groupname => 'root',
  keytype   => 'rsa',
}

file { '/root/.ssh/config':
  content => template('fuel/root_ssh_config.erb'),
  owner   => 'root',
  group   => 'root',
  mode    => '0600',
}

file { '/var/log/remote':
  ensure => directory,
  owner  => 'root',
  group  => 'root',
  mode   => '0750',
}

file { '/var/www/nailgun/dump':
  ensure => directory,
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

file { '/etc/dhcp/dhclient-enter-hooks':
  content => template('fuel/dhclient-enter-hooks.erb'),
  owner   => 'root',
  group   => 'root',
  mode    => '0755',
}

augeas { 'Cleanup orphaned dns settings from ifcfg-e* files':
  context => "/files/etc/sysconfig/network-scripts",
  changes => [
    "rm /files/etc/sysconfig/network-scripts/*[label() =~ glob('ifcfg-e*')]/DNS1",
    "rm /files/etc/sysconfig/network-scripts/*[label() =~ glob('ifcfg-e*')]/DNS2",
  ],
}

file { '/etc/dhcp/dhclient.conf':
  content => template('fuel/dhclient.conf.erb'),
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
}

#Suppress kernel messages to console
sysctl::value{ 'kernel.printk': value => '4 1 1 7' }

#Increase values for neighbour table
sysctl::value{ 'net.ipv4.neigh.default.gc_thresh1': value => '256' }
sysctl::value{ 'net.ipv4.neigh.default.gc_thresh2': value => '1024' }
sysctl::value{ 'net.ipv4.neigh.default.gc_thresh3': value => '2048' }

#Disable IPv6
sysctl::value{'net.ipv6.conf.all.disable_ipv6': value => '1'}
sysctl::value{'net.ipv6.conf.default.disable_ipv6': value => '1'}

class { '::openstack::reserved_ports':
  ports => '35357,41055,61613',
}

service { 'dhcrelay':
  ensure => stopped,
}

# Remove NetworkManager if installed
class { '::l23network':
  network_manager  => false,
  install_bondtool => false,
}

# Free disk space monitoring
file { '/etc/fuel/free_disk_check.yaml':
  content => template('fuel/free_disk_check.yaml.erb'),
  owner   => 'root',
  group   => 'root',
  mode    => '0755',
}

# Change link to UI on upgrades from old releases
exec { 'Change protocol and port in in issue':
  command => 'sed -i -e "s|http://\(.*\):8000\(.*\)|https://\1:8443\2|g" /etc/issue',
  onlyif  => 'grep -q 8000 /etc/issue',
}

if $::virtual != 'physical' {
  if ($::acpi_event == true and $::acpid_version == '1') or $::acpid_version == '2' {
    service { 'acpid':
      ensure => 'running',
      enable => true,
    }
  }
}

class { 'osnailyfacter::atop': }

class { 'osnailyfacter::ssh':
  password_auth  => 'yes',
  listen_address => ['0.0.0.0'],
  accept_env     => '# LANG LC_*',
}

class { 'fuel::iptables':
  admin_iface     => $::fuel_settings['ADMIN_NETWORK']['interface'],
  ssh_network     => $::fuel_settings['ADMIN_NETWORK']['ssh_network'],
  network_address => ipcalc_network_by_address_netmask($::fuel_settings['ADMIN_NETWORK']['ipaddress'],$::fuel_settings['ADMIN_NETWORK']['netmask']),
  network_cidr    => ipcalc_network_cidr_by_netmask($::fuel_settings['ADMIN_NETWORK']['netmask']),
}

# enable forwarding for the NAT/MASQUERADE configured by iptables
sysctl::value{ 'net.ipv4.ip_forward': value=>'1' }

# FIXME(kozhukalov): this should be a part of repo management tool
class { 'fuel::auxiliaryrepos':
  fuel_version => $::fuel_release,
  repo_root    => "/var/www/nailgun/${::fuel_openstack_version}",
}

class { 'openstack::clocksync':
  ntp_servers     => $ntp_servers,
  config_template => 'ntp/ntp.conf.erb',
}

class { 'openstack::logrotate':
  role     => 'server',
  rotation => 'weekly',
  keep     => '4',
  minsize  => '10M',
  maxsize  => '100M',
}

class { 'fuel::bootstrap_cli':
  settings              => $::fuel_settings['BOOTSTRAP'],
  direct_repo_addresses => [ $::fuel_settings['ADMIN_NETWORK']['ipaddress'], '127.0.0.1' ],
  bootstrap_cli_package => 'fuel-bootstrap-cli',
  config_path           => '/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml',
  config_wgetrc         => true,
}

augeas { 'Remove ssh_config SendEnv defaults':
  lens    => 'ssh.lns',
  incl    => '/etc/ssh/ssh_config',
  changes => [
    'rm */SendEnv',
    'rm SendEnv',
  ],
}

augeas { 'Password aging and length settings':
  lens    => 'login_defs.lns',
  incl    => '/etc/login.defs',
  changes => [
    'set PASS_MAX_DAYS 365',
    'set PASS_MIN_DAYS 2',
    'set PASS_MIN_LEN 8',
    'set PASS_WARN_AGE 30'
  ],
}

augeas { 'Password complexity':
  lens    => 'pam.lns',
  incl    => '/etc/pam.d/system-auth',
  changes => [
    "set *[type='password'][module='pam_pwquality.so' or module='pam_cracklib.so']/control requisite",
    "rm *[type='password'][module='pam_pwquality.so' or module='pam_cracklib.so']/argument",
    "set *[type='password'][module='pam_pwquality.so' or module='pam_cracklib.so']/argument[1] try_first_pass",
    "set *[type='password'][module='pam_pwquality.so' or module='pam_cracklib.so']/argument[2] retry=3",
    "set *[type='password'][module='pam_pwquality.so' or module='pam_cracklib.so']/argument[3] dcredit=-1",
    "set *[type='password'][module='pam_pwquality.so' or module='pam_cracklib.so']/argument[4] ucredit=-1",
    "set *[type='password'][module='pam_pwquality.so' or module='pam_cracklib.so']/argument[5] ocredit=-1",
    "set *[type='password'][module='pam_pwquality.so' or module='pam_cracklib.so']/argument[6] lcredit=-1",
  ],
  onlyif  => "match *[type='password'][control='requisite'][module='pam_pwquality.so' or module='pam_cracklib.so'] size > 0",
}

augeas { 'Enable only SSHv2 connections from the master node':
  lens    => 'ssh.lns',
  incl    => '/etc/ssh/ssh_config',
  changes => [
    'rm Protocol',
    'ins Protocol before Host[1]',
    'set Protocol 2',
  ],
}

augeas { 'Turn off sudo requiretty':
  changes => [
    'set /files/etc/sudoers/Defaults[*]/requiretty/negate ""',
  ],
}

file { '/etc/fuel-utils/config':
  content => template('fuel/fuel_utils_config.erb'),
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
}

# The requirement of former mcollective container.
# This directory is used for building target OS images.
file { ['/var/lib/fuel', '/var/lib/fuel/ibp']:
  ensure => directory,
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

# The requirement of former mcollective container.
# TODO(kozhukalov): make sure we need this
file { '/var/lib/hiera':
  ensure => directory,
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

# The requirement of former mcollective container.
# TODO(kozhukalov): make sure we need this
file { ['/etc/puppet/hiera.yaml', '/var/lib/hiera/common.yaml']:
  ensure => present,
}

exec { 'create-loop-devices':
  command => "/bin/bash -c 'for loopdev in \$(seq 1 9); do
  mknod \"/dev/loop\${loopdev}\" -m0660 b 7 \${loopdev} || :
done'"
}
