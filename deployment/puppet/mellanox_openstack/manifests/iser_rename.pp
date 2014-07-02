class mellanox_openstack::iser_rename ($storage_parent, $iser_interface_name){

  $interfaces_path = '/sys/class/net/'
  $iser_script_dir = '/opt/iser'
  $iser_rename_script = "$iser_script_dir/iser_rename.sh"

  file { $iser_script_dir:
    ensure => directory,
  }

  file { $iser_rename_script:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '500',
    content => template('mellanox_openstack/iser_rename.erb'),
  }

  exec { 'iser_rename':
    command   => "bash $iser_rename_script",
    unless    => "test -f $interfaces_path/$iser_interface_name",
    path      => ['/usr/bin','/usr/sbin','/bin','/sbin','/usr/local/bin'],
    logoutput => true,
    require   => File[$iser_rename_script],
  }

}

