# Definition: firewall::allow
#
define firewall::allow () {

  firewall { $title: ensure => present }

}
