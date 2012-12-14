class cobbler::snippets {

  define cobbler_snippet(){
    file {"/var/lib/cobbler/snippets/${name}":
      content => template("cobbler/snippets/${name}.erb"),
      owner => root,
      group => root,
      mode => 0644,
      require => Package[$cobbler::packages::cobbler_package],
      notify => Exec["cobbler_sync"]
    }
  }

  cobbler_snippet {"post_part_compute":}
  cobbler_snippet {"post_part_controller":}
  cobbler_snippet {"post_part_storage":}

  cobbler_snippet {"puppet_install_if_enabled":}
  cobbler_snippet {"puppet_conf":}
  cobbler_snippet {"puppet_register_if_enabled":}

  cobbler_snippet {'ntp_register_if_enabled':}

  cobbler_snippet {"mcollective_install_if_enabled":}
  cobbler_snippet {"mcollective_conf":}

  cobbler_snippet {"post_install_network_config":}

  cobbler_snippet {"cinder_create_lvm_group":}
  cobbler_snippet {"cinder_create_lvm_group__ubuntu":}

  cobbler_snippet {"ubuntu_disable_pxe":}
  cobbler_snippet {"ubuntu_packages":}
  cobbler_snippet {"ubuntu_puppet_config":}
  cobbler_snippet {"ubuntu_mcollective_config":}
  cobbler_snippet {"ubuntu_network":}

  case $operatingsystem {
    /(?i)(debian|ubuntu)/:  {
      file { "/usr/bin/late_command.py" :
        content => template("cobbler/scripts/late_command.py"),
        owner => root,
        group => root,
        mode => 0644,
      }
    }
  }

}
