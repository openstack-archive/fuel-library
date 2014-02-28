class tweaks::rabbitmq_attrupdater ($res_name="rabbit_attr",$cib_name="rabbit-attr") {

  cs_shadow { $res_name: cib => $cib_name }
  cs_commit { $res_name: cib => $cib_name }


  cs_resource { "$res_name":
      ensure => present,
      cib => $cib_name,
      primitive_class => 'ocf',
      provided_by     => 'mirantis',
      primitive_type => 'rabbit_master_attr',
      multistate_hash => {
        'type' => 'clone',
      },
      ms_metadata => {
        'interleave' => 'true',
        'globally-unique' => 'false'
      },
      operations => {
        'monitor' => {
          'interval' => '30',
          'timeout' => '60'
        },
        'start' => {
          'timeout' => '60'
        },
        'stop' => {
          'timeout' => '60'
        },
      },
  }

  file {'check_if_rabbit_master':
    path   => '/usr/local/bin/check_if_rabbit_master',
    mode   => '0755',
    owner  => root,
    group  => root,
    source => "puppet:///modules/cluster/check_if_rabbit_master",
  }->  file {'rabbit-attr-ocf':
    path   => '/usr/lib/ocf/resource.d/mirantis/rabbit_master_attr',
    mode   => '0755',
    owner  => root,
    group  => root,
    source => "puppet:///modules/cluster/rabbit_master_attr",
  }
  File<| title == 'ocf-mirantis-path' |> -> File['rabbit-attr-ocf']

  Package['rabbitmq-server'] -> File['rabbit-attr-ocf']

}
