## This is class installed nagios master
# ==Parameters
## proj_name       => isolated configuration for project
## templatehost    => checks,intervals parameters for hosts (as Hash)
# name - name of this template
# check_interval check command interval for hosts included in this group
#
## templateservice => checks,intervals parameters for services (as Hash)
# name - name of this template
# check_interval check command interval for services included in this group
#
## hostgroups      =>  create hostgroups
# Put all hostgroups from nrpe here (as Array)
class nagios::master (
$proj_name         = 'conf.d',
$hostgroups        = [],
$templatehost      = {'name' => 'default-host','check_interval' => '60'},
$templateservice   = {'name' => 'default-service' ,'check_interval'=>'60'},
$templatehost      = 'default-host',
$templateservice   = 'default-service',
$htpasswd          = {'nagiosadmin' => 'nagiosadmin'},
$contactgroups     = {'group' => 'admins', 'alias' => 'Admins'},
$contacts          = {'user' => 'hotkey', 'alias' => 'Dennis Hoppe',
                      'email' => 'nagios@%{domain}',
                      'group' => 'admins'},
) inherits nagios::params {

  validate_hash($htpasswd)
  validate_hash($templateservice)
  validate_hash($templatehost)
  validate_hash($contactgroups)
  validate_hash($contacts)

  include nagios::host
  include nagios::service
  include nagios::command
  include nagios::contact

  if $::osfamily == 'Debian' {
    exec { 'external-commands':
      command => 'dpkg-statoverride --update --add nagios nagios 751 /var/lib/nagios3 && dpkg-statoverride --update --add nagios www-data 2710 /var/lib/nagios3/rw',
      path    => ['/bin','/sbin','/usr/sbin/','/usr/sbin/'],
      unless  => 'dpkg-statoverride --list nagios nagios 751 /var/lib/nagios3 && dpkg-statoverride --list nagios www-data 2710 /var/lib/nagios3/rw',
      notify  => Service[$nagios::params::masterservice],
    }
  }

  # Bug: 3299
    exec { 'fix-permissions':
      command     => "chmod -R go+r /etc/${nagios::params::masterdir}/${proj_name}",
      path        => ['/bin','/sbin','/usr/sbin/','/usr/sbin/'],
      refreshonly => true,
      notify      => Service[$nagios::params::masterservice],
    }

  package { $nagios::params::nagios3pkg:
    ensure => present,
  }

  case $::osfamily {
    'RedHat': {
      augeas {'configs':
        lens    => 'NagiosCfg.lns',
        incl    => '/etc/nagios*/*.cfg',
        context => "/files/etc/${nagios::params::masterdir}/nagios.cfg",
        changes => [
          'rm cfg_file[position() > 1]',
          "set cfg_dir \"/etc/${masterdir}/${nagios::master::proj_name}\"",
          'set check_external_commands 1',
        ],
        require => Package[$nagios::params::nagios3pkg],
        notify  => Service[$nagios::params::masterservice],
      }
    }
    'Debian': {
      augeas {'configs':
        lens    => 'NagiosCfg.lns',
        incl    => '/etc/nagios*/*.cfg',
        context => "/files/etc/${nagios::params::masterdir}/nagios.cfg",
        changes => [
          "set cfg_dir[2] \"/etc/${masterdir}/${nagios::master::proj_name}\"",
          'set check_external_commands 1',
        ],
        require => Package[$nagios::params::nagios3pkg],
        notify  => Service[$nagios::params::masterservice],
      }
    }
  }

  File {
      owner   => root,
      group   => root,
      mode    => '0644',
      require => Package[$nagios::params::nagios3pkg],
  }

  file {
    "/etc/${nagios::params::masterdir}/${proj_name}/templates.cfg":
      content => template('nagios/openstack/templates.cfg.erb');
    "/etc/${nagios::params::masterdir}/${proj_name}/hostgroup.cfg":
      content => template('nagios/openstack/hostgroups.cfg.erb');
    "/etc/${nagios::params::masterdir}/${nagios::params::htpasswd}":
      content => template('nagios/common/etc/nagios3/htpasswd.users.erb');
  }

  file { "/etc/${nagios::params::masterdir}/${proj_name}":
    recurse => true,
    alias   => 'conf.d',
    notify  => Service[$nagios::params::masterservice],
    source  => 'puppet:///modules/nagios/common/etc/nagios3/conf.d',
  }

  Resources {
    purge => true,
  }

  resources {
    'nagios_command':;
    'nagios_contact':;
    'nagios_contactgroup':;
    'nagios_host':;
    'nagios_hostgroup':;
    'nagios_hostextinfo':;
    'nagios_service':;
    'nagios_servicegroup':;
  }

  service { $nagios::params::masterservice:
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [
      Augeas['configs'],
      File['conf.d'],
      Package[$nagios::params::nagios3pkg]
    ],
  }
}
