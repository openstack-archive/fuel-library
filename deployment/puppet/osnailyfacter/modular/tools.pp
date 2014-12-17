class { 'osnailyfacter::atop': }

package { 'screen':
  ensure => 'present',
}

class { 'puppet::pull' :
  modules_source   => hiera('puppet_modules_source'),
  manifests_source => hiera('puppet_manifests_source'),
}
