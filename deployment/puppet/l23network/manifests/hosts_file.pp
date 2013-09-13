class l23network::hosts_file ($hosts,$hosts_file="/etc/hosts") {

#Move original hosts file

exec {'copy hosts file':
  command => "cp ${hosts_file} /etc/hosts.header"
}
#
concat{ $hosts_file:
  owner => root,
  group => root,
  mode  => '0644'
}

concat::fragment{"hosts_local":
  target => $hosts_file,
  ensure => "/etc/hosts.header",
  order  => 01,
}
concat::fragment{"added_hosts":
  target  => $hosts_file,
  content => template("l23network/hosts.erb"),
  order   => 02
}
}


