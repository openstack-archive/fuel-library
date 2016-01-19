notice('MODULAR: conntrackd.pp')

$network_metadata = hiera_hash('network_metadata', {})
prepare_network_config(hiera_hash('network_scheme', {}))
$vrouter_name = hiera('vrouter_name', 'pub')

case $operatingsystem {
  Centos: { $conntrackd_package = 'conntrack-tools' }
  Ubuntu: { $conntrackd_package = 'conntrackd' }
}

# If VIP has namespace set to 'false' or 'undef' then we do not configure
# it under corosync cluster. So we should not configure colocation with it.
if $network_metadata['vips']["vrouter_${vrouter_name}"]['namespace'] {
  ### CONNTRACKD for CentOS 6 doesn't work under namespaces ##
  if $operatingsystem == 'Ubuntu' {
    $bind_address = get_network_role_property('mgmt/vip', 'ipaddr')
    $mgmt_bridge = get_network_role_property('mgmt/vip', 'interface')

    package { $conntrackd_package:
      ensure => installed,
    } ->

    file { '/etc/conntrackd/conntrackd.conf':
      content => template('cluster/conntrackd.conf.erb'),
    } ->

    cs_resource {'p_conntrackd':
      ensure          => present,
      primitive_class => 'ocf',
      provided_by     => 'fuel',
      primitive_type  => 'ns_conntrackd',
      metadata        => {
        'migration-threshold' => 'INFINITY',
        'failure-timeout'     => '180s'
      },
      parameters => {
        'bridge' => $mgmt_bridge,
      },
      complex_type => 'master',
      ms_metadata  => {
        'notify'          => 'true',
        'ordered'         => 'false',
        'interleave'      => 'true',
        'clone-node-max'  => '1',
        'master-max'      => '1',
        'master-node-max' => '1',
        'target-role'     => 'Master'
      },
      operations   => {
        'monitor'  => {
        'interval' => '30',
        'timeout'  => '60'
      },
      'monitor:Master' => {
        'role'         => 'Master',
        'interval'     => '27',
        'timeout'      => '60'
        },
      },
    }

    cs_colocation { "conntrackd-with-${vrouter_name}-vip":
      primitives => [ 'master_p_conntrackd:Master', "vip__vrouter_${vrouter_name}" ],
    }

    File['/etc/conntrackd/conntrackd.conf'] -> Cs_resource['p_conntrackd'] -> Service['p_conntrackd'] -> Cs_colocation["conntrackd-with-${vrouter_name}-vip"]

    service { 'p_conntrackd':
      ensure   => 'running',
      enable   => true,
      provider => 'pacemaker',
    }

    # Workaround to ensure log is rotated properly
    file { '/etc/logrotate.d/conntrackd':
      content => template('openstack/95-conntrackd.conf.erb'),
    }

    Package[$conntrackd_package] -> File['/etc/logrotate.d/conntrackd']
  }
}
