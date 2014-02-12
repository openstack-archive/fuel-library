class zabbix::app::puppet {

  @@zabbix_template { '$::fqdn Template Puppet Agent':
    name  => 'Template Puppet Agent',
    group => ['Templates'],
  }

  @@zabbix_item { '$::fqdn Puppet Run Date puppet.run.timestamp':
    name        => 'Puppet Run Date',
    key         => 'puppet.run.timestamp',
    delay       => '0',
    type        => '2',
    value_type  => '3',
    authtype    => '0',
    data_type   => '0',
    delta       => '0',
    description => 'The timestamp of the latest puppet run.',
    application => ['Puppet'],
  }

  @@zabbix_item { '$::fqdn Puppet Version puppet.version':
    name        => 'Puppet Version',
    key         => 'puppet.version',
    delay       => '0',
    type        => '2',
    value_type  => '4',
    authtype    => '0',
    data_type   => '0',
    delta       => '0',
    description => 'The puppet version string reported in the last puppet run.',
    application => ['Puppet'],
  }

  @@zabbix_item { '$::fqdn Puppet Run Total Time puppet.run.time':
    name        => 'Puppet Run Total Time',
    key         => 'puppet.run.time',
    delay       => '0',
    type        => '2',
    value_type  => '0',
    authtype    => '0',
    data_type   => '0',
    delta       => '0',
    description => 'The total time in seconds for the puppet run to complete. This will be 0.0 if the puppet run status is failed.

  See the puppet wiki for puppet report details: http://projects.puppetlabs.com/projects/puppet/wiki/Report_Format_2',
    application => ['Puppet'],
  }

  @@zabbix_item { '$::fqdn Time Since Last Puppet Run puppet.run.time_since_last':
    name        => 'Time Since Last Puppet Run',
    key         => 'puppet.run.time_since_last',
    delay       => '120',
    type        => '15',
    value_type  => '3',
    authtype    => '0',
    data_type   => '0',
    delta       => '0',
    description => 'Calculate the number of seconds since the last puppet run. This is used to alarm when it has been too long.',
    application => ['Puppet'],
  }

  @@zabbix_item { '$::fqdn Puppet Run Status puppet.run.status':
    name        => 'Puppet Run Status',
    key         => 'puppet.run.status',
    delay       => '0',
    type        => '2',
    value_type  => '4',
    authtype    => '0',
    data_type   => '0',
    delta       => '0',
    description => 'The status of the latest puppet run. Value will be one of "changed", "failed", or "unchanged".',
    application => ['Puppet'],
  }

  @@zabbix_trigger { '$::fqdn Puppet run had changes on {HOSTNAME}':
    name        => 'Puppet run had changes on {HOSTNAME}',
    description => 'The most recent puppet run made changes on this host. Check the logs on the host and the puppet master to see what happened.

  The agent logs are usually in syslog (/var/log/syslog or /var/log/messages). The master logs are usually in /var/log/daemon.log and /var/log/puppet/.',
    expression  => '{Template_Puppet_Agent:puppet.run.status.strlen(0)}=7 & {Template_Puppet_Agent:puppet.run.status.str(changed)}=1',
    priority    => '1',
    status      => '0',
    type        => '0',
  }

  @@zabbix_trigger { '$::fqdn Puppet version changed on {HOSTNAME}':
    name        => 'Puppet version changed on {HOSTNAME}',
    description => 'The puppet version string has changed since the last puppet run on this host.',
    expression  => '{Template_Puppet_Agent:puppet.version.diff(0)}>0',
    priority    => '1',
    status      => '0',
    type        => '0',
  }

  @@zabbix_trigger { '$::fqdn Puppet has not run recently on {HOSTNAME}':
    name        => 'Puppet has not run recently on {HOSTNAME}',
    description => 'Alarm when puppet has not reported a run in over 90 minutes. This could be a sign that the puppet agent is unable to connect to the puppet master for some reason (ie a certificate error).',
    expression  => '{Template_Puppet_Agent:puppet.run.time_since_last.prev(0)}>5400',
    priority    => '2',
    status      => '0',
    type        => '0',
  }

  @@zabbix_trigger { '$::fqdn Puppet run failed on {HOSTNAME}':
    name        => 'Puppet run failed on {HOSTNAME}',
    description => 'The most recent puppet run failed on this host. Check the logs on the host and the puppet master to see what happened.

  The agent logs are usually in syslog (/var/log/syslog or /var/log/messages). The master logs are usually in /var/log/daemon.log and /var/log/puppet/.',
    expression  => '{Template_Puppet_Agent:puppet.run.status.str(failed)}=1',
    priority    => '3',
    status      => '0',
    type        => '0',
  }

  @@zabbix_application { '$::fqdn Puppet':
    name => 'Puppet',
  }

  @@zabbix_hostgroup { '$::fqdn Templates':
    name => 'Templates',
  }

}