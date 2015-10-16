class nailgun::packages(
  $gem_source = "http://rubygems.org/",
  ){

  nailgun::nailgun_safe_package { "iptables": }
  nailgun::nailgun_safe_package { "supervisor": }
  nailgun::nailgun_safe_package { "nginx": }
  nailgun::nailgun_safe_package { "crontabs": }
  nailgun::nailgun_safe_package { "cronie-anacron": }
  nailgun::nailgun_safe_package { "postgresql-libs": }
  nailgun::nailgun_safe_package { "rsyslog": }
  nailgun::nailgun_safe_package { "rsync": }
  nailgun::nailgun_safe_package { "fence-agents": }
  nailgun::nailgun_safe_package { "python-fuelclient": }
  nailgun::nailgun_safe_package { "screen": }
  nailgun::nailgun_safe_package { "fuel-migrate": }
  nailgun::nailgun_safe_package { "acpid": }
}
