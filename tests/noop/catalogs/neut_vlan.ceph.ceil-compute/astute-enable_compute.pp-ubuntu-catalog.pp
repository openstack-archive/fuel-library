class { 'Nova::Params':
  name => 'Nova::Params',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

service { 'nova-compute':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'nova-compute',
}

stage { 'main':
  name => 'main',
}

