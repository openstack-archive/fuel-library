class nailgun::free-disk-check (
$free_disk = 3
)
{
  include nailgun::packages

  file { '/usr/bin/free_disk_check.py':
    source  => 'puppet:///modules/nailgun/free_disk_check.py',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { '/etc/fuel/free-disk-check.yaml':
    content => template('nailgun/free_disk_check.yaml.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { '/etc/cron.hourly/1free-disk-check':
    source  => 'puppet:///modules/anacron/free-disk-check',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }
}
