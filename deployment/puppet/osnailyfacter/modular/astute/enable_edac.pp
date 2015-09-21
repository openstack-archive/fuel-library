require 'kmod'

notice('MODULAR: enable_edac.pp')

$module = 'edac_core'

$options_to_enable = ["check_pci_errors", "edac_mc_log_ce", "edac_mc_log_ue"]


define edac_option ($value) {
  kmod::option { "option ${title}":
    option => $title,
    value => $value,
    module => $module
  }

  $config_file = "/sys/module/${module}/parameters/${title}"
  exec { "update ${title}":
    path    => '/usr/bin:/usr/sbin:/sbin:/bin',
    command => "echo -n '${value}' > '${config_file}'",
    onlyif  => "test -w '${config_file}' && test '${value}' != `cat '${config_file}'`"
  }
}


edac_option { $options_to_enable:
    value => 1
}

kmod::load { $module: }
