class keepalived::install {
  package { 'keepalived':
    ensure => present,
  }
}
