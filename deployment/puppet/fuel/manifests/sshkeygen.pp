define fuel::sshkeygen (
  $length = 2048,
  $homedir = "/root",
  $username = "root",
  $groupname = "root",
  $keytype = "rsa",
){

  Exec { path => '/usr/bin:/bin:/usr/sbin:/sbin' }

  if !($keytype in ['rsa', 'dsa']) {
    fail("Wrong keytype parameter: ${keytype}")
  }

  file { $homedir :
    ensure => 'directory',
    mode   => '0755',
    owner  => $username,
    group  => $groupname,
  }

  file { "${homedir}/.ssh" :
    ensure  => 'directory',
    mode    => '0700',
    owner   => $username,
    group   => $groupname,
    require => File[$homedir],
  }

  exec { "Generate ssh key for #{username}":
    command => "ssh-keygen -t ${keytype} -b ${length} -N '' -f ${homedir}/.ssh/id_${keytype}",
    creates => "${homedir}/.ssh/id_${keytype}",
    user    => $username,
    group   => $groupname,
    require => File["${homedir}/.ssh"],
  }

  file { "${homedir}/.ssh/id_${keytype}":
    owner   => $username,
    group   => $groupname,
    mode    => '0600',
    require => Exec["Generate ssh key for #{username}"],
  }

  exec { "Public ssh key for #{username}":
    command => "ssh-keygen -y -f ${homedir}/.ssh/id_${keytype} > ${homedir}/.ssh/id_${keytype}.pub",
    creates => "${homedir}/.ssh/id_${keytype}.pub",
    user    => $username,
    group   => $groupname,
    require => [
      File["${homedir}/.ssh"],
      Exec["Generate ssh key for #{username}"],
    ]
  }

  file { "${homedir}/.ssh/id_${keytype}.pub":
    owner   => $username,
    group   => $groupname,
    mode    => '0644',
    require => Exec["Public ssh key for #{username}"],
  }

  exec { "copy public key to authorized_keys":
    command => "cat ${homedir}/.ssh/id_${keytype}.pub | tee -a ${homedir}/.ssh/authorized_keys",
    require => File["${homedir}/.ssh/id_${keytype}.pub"]
  }
}
