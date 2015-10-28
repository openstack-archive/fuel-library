class { 'Settings':
  name => 'Settings',
}

class { 'Umm::Common':
  name    => 'Umm::Common',
  release => 'u1404',
}

class { 'Umm':
  name => 'Umm',
}

class { 'main':
  name => 'main',
}

exec { 'umm-install':
  command     => '/tmp/umm-install.sh',
  path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
  refreshonly => 'false',
  require     => 'File[umm-install.sh]',
}

file { 'issue.mm':
  ensure => 'present',
  group  => 'root',
  mode   => '0770',
  owner  => 'root',
  path   => '/etc/issue.mm',
  source => 'puppet:///modules/umm/issue.mm',
}

file { 'umm-br.conf':
  ensure => 'present',
  group  => 'root',
  mode   => '0660',
  owner  => 'root',
  path   => '/etc/init/umm-br.conf',
  source => 'puppet:///modules/umm/umm-br.conf',
}

file { 'umm-console.conf':
  ensure => 'present',
  group  => 'root',
  mode   => '0660',
  owner  => 'root',
  path   => '/etc/init/umm-console.conf',
  source => 'puppet:///modules/umm/umm-console.conf',
}

file { 'umm-install.sh':
  group  => 'root',
  mode   => '0770',
  owner  => 'root',
  path   => '/tmp/umm-install.sh',
  source => 'puppet:///modules/umm/umm-install.u1404',
}

file { 'umm-run.conf':
  ensure => 'present',
  group  => 'root',
  mode   => '0660',
  owner  => 'root',
  path   => '/etc/init/umm-run.conf',
  source => 'puppet:///modules/umm/umm-run.conf',
}

file { 'umm-tr.conf':
  ensure => 'present',
  group  => 'root',
  mode   => '0660',
  owner  => 'root',
  path   => '/etc/init/umm-tr.conf',
  source => 'puppet:///modules/umm/umm-tr.conf',
}

file { 'umm.conf':
  ensure => 'present',
  group  => 'root',
  mode   => '0660',
  owner  => 'root',
  path   => '/etc/umm.conf',
  source => 'puppet:///modules/umm/umm.conf',
}

file { 'umm.sh':
  ensure => 'present',
  group  => 'root',
  mode   => '0770',
  owner  => 'root',
  path   => '/etc/profile.d/umm.sh',
  source => 'puppet:///modules/umm/umm.sh',
}

file { 'umm':
  ensure => 'present',
  group  => 'root',
  mode   => '0770',
  owner  => 'root',
  path   => '/usr/local/bin/umm',
  source => 'puppet:///modules/umm/umm',
}

file { 'umm_svc.u1404':
  ensure  => 'present',
  group   => 'root',
  mode    => '0770',
  owner   => 'root',
  path    => '/usr/lib/umm/umm_svc.u1404',
  require => 'File[ummlib]',
  source  => 'puppet:///modules/umm/umm_svc.u1404',
}

file { 'umm_svc':
  ensure  => 'present',
  group   => 'root',
  mode    => '0770',
  owner   => 'root',
  path    => '/usr/lib/umm/umm_svc',
  require => 'File[ummlib]',
  source  => 'puppet:///modules/umm/umm_svc',
}

file { 'umm_vars':
  ensure  => 'present',
  content => '[ -f /etc/umm.conf ] && . /etc/umm.conf
UMM_R=u1404
UMM=${UMM:=no}

REBOOT_COUNT=${REBOOT_COUNT:=2}
COUNTER_RESET_TIME=${COUNTER_RESET_TIME:=10}
UMM_FLAG=${UMM_FLAG:=/var/run/umm.lock}
UMM_LIB=${UMM_LIB:=/usr/lib/umm}
UMM_DATA=${UMM_DATA:=/var/lib/umm}

[ -f ${UMM_DATA}/boot_data ] && . ${$UMM_DATA}/boot_data

UMM_DRC=0
for i in $(ls ${UMM_DATA}/*.var 2>/dev/null) ; do
    . $i
done
',
  group   => 'root',
  mode    => '0770',
  owner   => 'root',
  path    => '/usr/lib/umm/umm_vars',
  require => 'File[ummlib]',
}

file { 'ummlib':
  ensure  => 'directory',
  path    => '/usr/lib/umm',
  require => 'File[ummvar]',
}

file { 'ummvar':
  ensure => 'directory',
  path   => '/var/lib/umm',
}

stage { 'main':
  name => 'main',
}

