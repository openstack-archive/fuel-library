class { 'Cinder::Params':
  name => 'Cinder::Params',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

service { 'cinder-volume':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'cinder-volume',
}

stage { 'main':
  name => 'main',
}

