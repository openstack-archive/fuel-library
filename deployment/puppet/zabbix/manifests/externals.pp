# == Class: zabbix::zabbix
#
# virtuals and userparms for the api
#
# most classes should have something like this, in most cases it should be
# called modulename::zabbix. This is also why the user parameters are in
# here. It is expected that other modules either implement similar patterns
# to interface with this, they might even inherit this class.
#
# === Parameters
#
# [*ensure*]
#   absent or present
# [*api*]
#   enable exports based api calls, default false
# [*params*]
#   enable uerparameters, default true
#
class zabbix::externals (
  $ensure = undef,
  $api    = undef
) inherits zabbix::params {

  $ensure_real = $ensure ? {
    undef   => $zabbix::params::api,
    default => $api
  }
  $api_real    = $api ? {
    undef   => $zabbix::params::api_ensure,
    default => $api
  }

  if $api_real {
    # add the template for puppet report in zabbix
    @@zabbix_template { 'Template Puppet Agent':
      ensure => $ensure_real,
    }

    @@zabbix_template_application { 'Puppet':
      ensure => $ensure_real,
      host   => 'Template Puppet Agent',
    }

    @@zabbix_template_item { 'Puppet Run Date':
      description  => 'The timestamp of the latest run.',
      key          => 'puppet.run.timestamp',
      applications => ['Puppet'],
      type         => 2,
      value_type   => 3,
    }

    @@zabbix_template_item { 'Puppet Run Status':
      description  => 'The status of the latest run.',
      key          => 'puppet.run.status',
      applications => ['Puppet'],
      type         => 2,
      value_type   => 4,
    }

    @@zabbix_template_item { 'Puppet Run Total Time':
      description  => 'The total time in seconds for the run to complete.',
      key          => 'puppet.run.time',
      applications => ['Puppet'],
      type         => 2,
      value_type   => 0,
    }

    @@zabbix_template_item { 'Puppet Version':
      description  => 'The puppet version string reported in the last run.',
      key          => 'puppet.version',
      applications => ['Puppet'],
      type         => 2,
      value_type   => 4,
    }

    # @todo implement params for type = 15
    #    @@zabbix_template_item { 'Time Since Last Puppet Run':
    #      description => 'Calculate the number of seconds since the last puppet
    #      run.',
    #      key => 'puppet.run.time_since_last',
    #      applications => ['Puppet'],
    #      type => 15,
    #      params => 'last(system.localtime) - last(puppet.run.timestamp)',
    #      value_type => 3
    #    }

    $last_time = '{Template_Puppet_Agent:puppet.run.time_since_last.prev(0)}'
    $trigger_run = "${last_time}>5400"

    @@zabbix_trigger { $trigger_run:
      description => 'Puppet has not run recently on {HOSTNAME}',
      comments    => 'todo',
      priority    => 2,
      status      => 0,
      type        => 0,
    }

    $len_check = '{Template_Puppet_Agent:puppet.run.status.strlen(0)}=7'
    $str_check = '{Template_Puppet_Agent:puppet.run.status.str(changed)}=1'
    $trigger_change = "${len_check} & ${str_check}"

    @@zabbix_trigger { $trigger_change:
      description => 'Puppet run had changes on {HOSTNAME}',
      comments    => 'todo',
      priority    => 3,
      status      => 0,
      type        => 0,
    }
    $trigger_version = '{Template_Puppet_Agent:puppet.version.diff(0)}>0'

    @@zabbix_trigger { $trigger_version:
      description => 'Puppet version changed on {HOSTNAME}',
      comments    => 'todo',
      priority    => 1,
      status      => 0,
      type        => 0,
    }

    # create hostgroups for puppetized servers
    $hostgroups = ['Puppet Clients', $::operatingsystem, $::osfamily]

    @@zabbix_hostgroup { $hostgroups:
    }

    # and host for self
    # @todo needs to be parametrized to be useful
    @@zabbix_host { $::fqdn:
      status => 0,
      groups => $hostgroups
    }
  }
}
