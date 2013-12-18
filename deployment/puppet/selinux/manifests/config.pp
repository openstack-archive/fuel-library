# Class: selinux::config
#
# Description
#  This class is designed to configure the system to use SELinux on the system
#
# Parameters:
#  - $mode (enforced|permissive|disabled) - sets the operating state for SELinux.
# 
# Actions:
#  Configures SELinux to a specific state (enforced|permissive|disabled)
#
# Requires:
#  This module has no requirements
#
# Sample Usage:
#  This module should not be called directly.
#
class selinux::config(
  $mode
) {
  Exec {path => [ '/bin', '/usr/bin', '/usr/local/bin', '/sbin', '/usr/sbin', '/usr/local/sbin' ]}

  file { $selinux::params::sx_mod_dir:
    ensure => directory,
  }

  # Check to see if the mode set is valid.
  if $mode == 'enforcing' or $mode == 'permissive' or $mode == 'disabled' {
    exec { "set-selinux-config-to-${mode}":
      command => "sed -i \"s@^\\(SELINUX=\\).*@\\1${mode}@\" /etc/selinux/config",
      unless  => "grep -q \"SELINUX=${mode}\" /etc/selinux/config",
    }
    exec { "disable-selinux-relabeling":
      command => "rm -f /.autorelabel",
    }

    case $mode {
      permissive,disabled: { 
        $sestatus = '0'

        # workaround bugfix (http://projects.puppetlabs.com/issues/4466)
        case $::osfamily {
          'RedHat': {
        $facter_selinux_path = '/usr/lib/ruby/site_ruby/1.8/facter/selinux.rb'
            }
	         'Debian': {
	            $facter_selinux_path = '/usr/lib/ruby/vendor_ruby/facter/selinux.rb'
	          }
	      }

        exec { "patch-facter-selinux":
          command => "sed -i 's|proc/self/attr/current\") !|proc/self/attr/current\") rescue \"kernel\\\\0\" !|' ${facter_selinux_path}",
          unless  => "grep -q 'rescue \"kernel' ${facter_selinux_path}",
        }

        if $mode == 'disabled' and $::selinux_current_mode == 'permissive' {
          notice('A reboot is required to fully disable SELinux. SELinux will operate in Permissive mode until a reboot')
        }
      }
      enforcing: {
        $sestatus = '1'
      }
    }

    exec { "change-selinux-status-to-${mode}":
      command => "echo ${sestatus} > /selinux/enforce",
      unless  => "grep -q '${sestatus}' /selinux/enforce",
    }

  } else {
    fail("Invalid mode specified for SELinux: ${mode}")
  }
}
