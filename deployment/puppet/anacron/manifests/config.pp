# Make periodic cron jobs run in the idle scheduling class to reduce
# their impact on other system activities.
# Make anacron being manage 20-fuel logrotate job in /etc/cron.hourly
# for RHEL/CENTOS, and same by cron (it does by default) for DEBIAN/UBUNTU
class anacron::config {

File {
  ensure => file,
  owner  => root,
  group  => root,
  mode   => 0644,
}

case $::operatingsystem {
    /(?i)(centos|redhat)/:  {
# assumes package cronie-anacron were istalled at BM
        file { '/etc/anacrontab': source  => 'puppet:///modules/anacron/anacrontab', }
        file { '/etc/cron.d/0hourly' : source => 'puppet:///modules/anacron/0hourly', }
        file { '/etc/cron.hourly/logrotate' : mode => 0755, source => 'puppet:///modules/anacron/logrotate-hourly', }
        file { '/etc/cron.hourly/0anacron' : mode => 0755, source => 'puppet:///modules/anacron/0anacron-hourly', }
    }
    /(?i)(debian|ubuntu)/:  {
# assumes package anacron were installed at BM
        file { '/etc/anacrontab': source  => 'puppet:///modules/anacron/anacrontab-ubuntu', }
        file { '/etc/cron.d/anacron' : source => 'puppet:///modules/anacron/anacron-ubuntu', }
        file { '/etc/cron.hourly/logrotate' : mode => 0755, source => 'puppet:///modules/anacron/logrotate-hourly-ubuntu', }
        #file { '/etc/cron.hourly/0anacron' : mode => 0755, source => 'puppet:///modules/anacron/0anacron-hourly-ubuntu', }
    }
  }
}

