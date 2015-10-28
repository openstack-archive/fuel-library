class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

package { 'fuel-ha-utils':
  ensure => 'latest',
  name   => 'fuel-ha-utils',
}

package { 'fuel-misc':
  ensure => 'latest',
  name   => 'fuel-misc',
}

stage { 'main':
  name => 'main',
}

