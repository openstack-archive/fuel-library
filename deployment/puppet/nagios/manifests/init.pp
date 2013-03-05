## This is class installed nagios NRPE
# ==Parameters
## proj_name => isolated configuration for project
## services  =>  array of services which you want use
## whitelist =>  array of IP addreses which NRPE trusts
## hostgroup =>  group wich will use in nagios master
# do not forget create it in nagios master
class nagios (
$services,
$servicegroups     = false,
$hostgroup         = false,
$proj_name         = 'nrpe.d',
$whitelist         = '127.0.0.1',
$nrpepkg           = $nagios::params::nrpepkg,
$nrpeservice       = $nagios::params::nrpeservice,
) inherits nagios::params  {

  $master_proj_name = "${proj_name}_master"
  validate_array($services)

  include nagios::common

  nagios::nrpeconfig { '/etc/nagios/nrpe.cfg':
    whitelist   => $whitelist,
    include_dir => "/etc/nagios/${proj_name}",
  }

  package {$nrpepkg:}

  if inline_template("<%= !(services & ['swift-proxy', 'swift-account',
    'swift-container', 'swift-object', 'swift-ring']).empty? -%>") == 'true' {
    package {'nagios-plugins-os-swift':
      require => Package[$nrpepkg],
    }
  }

  if member($services, 'libvirt') == true {
    package {'nagios-plugins-os-libvirt':
      require => Package[$nrpepkg],
    }
  }

  File {
    force   => true,
    purge   => true,
    recurse => true,
    owner   => root,
    group   => root,
    mode    => '0644',
  }

  file { "/etc/nagios/${proj_name}/openstack.cfg":
    content => template('nagios/openstack/openstack.cfg.erb'),
    notify  => Service[$nrpeservice],
    require => Package[$nrpepkg],
  }

  file { "/etc/nagios/${proj_name}/commands.cfg":
    content => template('nagios/common/etc/nagios/nrpe.d/commands.cfg.erb'),
    notify  => Service[$nrpeservice],
    require => Package[$nrpepkg],
  }

  file { "/etc/nagios/${proj_name}":
    source  => 'puppet:///modules/nagios/common/etc/nagios/nrpe.d',
    notify  => Service[$nrpeservice],
    require => Package[$nrpepkg],
  }

  file { "/usr/local/lib/nagios":
    mode    => '0755',
    source  => 'puppet:///modules/nagios/common/usr/local/lib/nagios',
  }

  service {$nrpeservice:
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => false,
    pattern    => 'nrpe',
    require    => [
      File['nrpe.cfg'],
      Package[$nrpepkg]
    ],
  }
}
