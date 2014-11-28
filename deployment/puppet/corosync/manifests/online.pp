class corosync::online {
  $ssh_private_key = '/var/lib/astute/nova/nova'
  $ssh_public_key  = '/var/lib/astute/nova/nova.pub'

  install_ssh_keys { 'ssh_key_for_corosync' :
    ensure           => 'present',
    user             => 'root',
    private_key_path => $ssh_private_key,
    public_key_path  => $ssh_public_key,
    private_key_name => 'id_rsa',
    public_key_name  => 'id_rsa.pub',
    authorized_keys  => 'authorized_keys',
  }

  file { '/root/.ssh/config' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => "Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null\n",
  }

  pcmk_reload { 'online' :}

  Install_ssh_keys['ssh_key_for_corosync'] -> Pcmk_reload <||>
  File['/root/.ssh/config'] -> Pcmk_reload <||>
  Pcmk_reload <||> -> Service <| provider == 'pacemaker' |>

}
