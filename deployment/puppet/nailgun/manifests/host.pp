class nailgun::host(
  $production,
  $nailgun_group = "nailgun",
  $nailgun_user = "nailgun",

  $gem_source = "http://localhost/gems/",

  ) {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  anchor { "nailgun-begin": }
  anchor { "nailgun-end": }

  Anchor<| title == "nailgun-begin" |> ->
  Class["nailgun::iptables"] ->
  Class["nailgun::user"] ->
  Anchor<| title == "nailgun-end" |>


  firewall { '002 accept related established rules':
    proto   => 'all',
    state   => ['RELATED', 'ESTABLISHED'],
    action  => 'accept',
  } -> class { "nailgun::iptables": }


  class { "nailgun::user":
    nailgun_group => $nailgun_group,
    nailgun_user => $nailgun_user,
  }
  class { "cobbler::iptables": }

  if $production =~ /docker/ {
    nailgun::sshkeygen { "/root/.ssh/id_rsa":
      homedir => "/root",
      username => "root",
      groupname => "root",
      keytype => "rsa",
    }
  } else {
    nailgun::sshkeygen { "/root/.ssh/id_rsa":
      homedir => "/root",
      username => "root",
      groupname => "root",
      keytype => "rsa",
    } ->
    exec { "cp /root/.ssh/id_rsa.pub /etc/cobbler/authorized_keys":
      command => "cp /root/.ssh/id_rsa.pub /etc/cobbler/authorized_keys",
      creates => "/etc/cobbler/authorized_keys",
      require => Class["nailgun::cobbler"],
    }
  }

  file { "/etc/ssh/sshd_config":
    content => template("nailgun/sshd_config.erb"),
    owner => root,
    group => root,
    mode => 0600,
  }

  file { "/root/.ssh/config":
    content => template("nailgun/root_ssh_config.erb"),
    owner => root,
    group => root,
    mode => 0600,
  }

}
