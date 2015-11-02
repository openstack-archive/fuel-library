# == Class: osnailyfacter::puppet_pull
#
# Installs a convenience script to pull manifests from master node
#
# == Parameters
#
# [*script*]
#  Specifies path where script will be installed
#
# [*template*]
#  Specifies template to be used for script
#
# [*modules_source*]
#  Specifies location from which modules will be pulled
#
# [*manifests_source*]
#  Specifies location from which manifests will be pulled
#

class osnailyfacter::puppet_pull (
  $script           = '/usr/local/bin/puppet-pull',
  $template         = "${module_name}/puppet-pull.sh.erb",
  $modules_source   = 'rsync://10.20.0.2/puppet/modules',
  $manifests_source = 'rsync://10.20.0.2/puppet/manifests',
) {

  file { $script :
    ensure  => present,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => template($template),
  }

}
