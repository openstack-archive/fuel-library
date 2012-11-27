class cobbler::selinux {
  case $operatingsystem {
    /(?i)(centos|redhat)/: {

      exec { "cobbler_disable_selinux":
        command => "setenforce 0",
        onlyif => "getenforce | grep -q Enforcing"
      }

      exec { "cobbler_disable_selinux_permanent":
        command => "sed -ie \"s/^SELINUX=enforcing/SELINUX=disabled/g\" /etc/selinux/config",
        onlyif => "grep -q \"^SELINUX=enforcing\" /etc/selinux/config"
      }

    }
  }
}
