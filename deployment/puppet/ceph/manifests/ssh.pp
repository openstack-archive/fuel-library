# generate and install SSH keys for Ceph
class ceph::ssh {

  $ssh_config = "${::ceph::svc_user_homedir}/.ssh/config"
  $private_key = '/var/lib/astute/ceph/ceph'
  $public_key  = '/var/lib/astute/ceph/ceph.pub'

  install_ssh_keys {'svc_user_ssh_keys_for_ceph':
    ensure           => present,
    user             => $::ceph::svc_user_name,
    private_key_path => $private_key,
    public_key_path  => $public_key,
    private_key_name => 'id_rsa',
    public_key_name  => 'id_rsa.pub',
    authorized_keys  => 'authorized_keys',
  }

  if !defined(File[$ssh_config]) {
    file { $ssh_config :
      mode    => '0600',
      content => "Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null\n",
    }
  }

  Install_ssh_keys['svc_user_ssh_keys_for_ceph'] -> File[$ssh_config]
}
