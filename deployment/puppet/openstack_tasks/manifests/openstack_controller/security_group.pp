# Copyright (C) 2015-2016 Mirantis

class openstack_tasks::openstack_controller::security_group {
  notice('MODULAR: openstack_controller/security_group.pp')

  $nova_hash = hiera_hash('nova', {})

  if pick($nova_hash['create_default_security_groups'], true) {
    Nova_security_rule {
      ensure      => present,
      ip_protocol => 'tcp',
      ip_range    => '0.0.0.0/0',
    }

    nova_security_group { 'global_http':
      ensure      => present,
      description => 'Allow HTTP traffic'
    }

    nova_security_rule { 'http_01':
      from_port => '80',
      to_port => '80',
      security_group => 'global_http'
    }

    nova_security_rule { 'http_02':
      from_port => '443',
      to_port => '443',
      security_group => 'global_http'
    }

    nova_security_group { 'global_ssh':
      ensure      => present,
      description => 'Allow SSH traffic'
    }

    nova_security_rule { 'ssh_01':
      from_port => '22',
      to_port => '22',
      security_group => 'global_ssh'
    }

    nova_security_group { 'allow_all':
      ensure      => present,
      description => 'Allow all traffic'
    }

    nova_security_rule { 'all_01':
      from_port => '1',
      to_port => '65535',
      security_group => 'allow_all'
    }

    nova_security_rule { 'all_02':
      ip_protocol => 'udp',
      from_port => '1',
      to_port => '65535',
      security_group => 'allow_all'
    }

    nova_security_rule { 'all_03':
      ip_protocol => 'icmp',
      from_port => '1',
      to_port => '255',
      security_group => 'allow_all'
    }
  } else {
    nova_security_group { ['global_http', 'global_ssh', 'allow_all']:
      ensure => absent
    }
  }
}
