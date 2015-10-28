class { 'Openstack::Logging':
  debug            => 'false',
  escapenewline    => 'false',
  keep             => '4',
  log_auth_local   => 'true',
  log_local        => 'true',
  log_remote       => 'true',
  maxsize          => '100M',
  minsize          => '10M',
  name             => 'Openstack::Logging',
  port             => '514',
  production       => 'prod',
  proto            => 'udp',
  rabbit_log_level => 'NOTICE',
  role             => 'client',
  rotation         => 'weekly',
  rservers         => {'port' => '514', 'remote_type' => 'tcp', 'server' => '10.108.0.2'},
  show_timezone    => 'true',
  virtual          => 'false',
}

class { 'Openstack::Logrotate':
  debug    => 'false',
  keep     => '4',
  maxsize  => '100M',
  minsize  => '10M',
  name     => 'Openstack::Logrotate',
  role     => 'client',
  rotation => 'weekly',
}

class { 'Rsyslog::Client':
  custom_config  => '',
  escapenewline  => 'false',
  log_auth_local => 'true',
  log_local      => 'true',
  log_remote     => 'true',
  name           => 'Rsyslog::Client',
  remote_type    => 'tcp',
  server         => 'log',
}

class { 'Rsyslog::Config':
  name => 'Rsyslog::Config',
}

class { 'Rsyslog::Install':
  name => 'Rsyslog::Install',
}

class { 'Rsyslog::Params':
  name => 'Rsyslog::Params',
}

class { 'Rsyslog::Service':
  name => 'Rsyslog::Service',
}

class { 'Rsyslog':
  name => 'Rsyslog',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

cron { 'fuel-logrotate':
  command => '/usr/bin/fuel-logrotate',
  minute  => '*/30',
  name    => 'fuel-logrotate',
  user    => 'root',
}

file { '/etc/default/rsyslog':
  ensure  => 'file',
  content => '# File is managed by puppet

RSYSLOGD_OPTIONS=""
# CentOS, RedHat, Fedora
SYSLOGD_OPTIONS="${RSYSLOGD_OPTIONS}"
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'root',
  path    => '/etc/default/rsyslog',
}

file { '/etc/logrotate.d/fuel.nodaily':
  content => '# managed by puppet

"/var/log/audit/audit.log"
"/var/log/ceilometer/*.log"
"/var/log/cinder/*.log"
"/var/log/glance/*.log"
"/var/log/heat/*.log"
"/var/log/keystone/*.log"
"/var/log/murano/*.log"
"/var/log/neutron/*.log"
"/var/log/nova/*.log"
"/var/log/sahara/*.log"
"/var/log/*-all.log"
"/var/log/auth.log"
"/var/log/corosync.log"
"/var/log/cron.log"
"/var/log/daemon.log"
"/var/log/dashboard.log"
"/var/log/debug"
"/var/log/kern.log"
"/var/log/mail.log"
"/var/log/messages"
"/var/log/mongod.log"
"/var/log/mysqld.log"
"/var/log/nailgun-agent.log"
"/var/log/pacemaker.log"
"/var/log/sudo.log"
"/var/log/syslog"
"/var/log/user.log"
"/var/log/upstart/*.log"
{
  # truncate file, do not delete & recreate
  copytruncate

  # compress rotated files with gzip
  compress

  # postpone compression to the next rotation
  delaycompress

  # ignore missing files
  missingok

  # do not rotate empty files
  notifempty

  # logrotate allows to use only year, month, day and unix epoch
  dateformat -%Y%m%d-%s

  # number of rotated files to keep
  rotate 4

  # do not rotate files unless both size and time conditions are met
  weekly
  minsize 10M

  # force rotate if filesize exceeded 100M
  maxsize 100M

  
  # https://bugs.launchpad.net/ubuntu/+source/logrotate/+bug/1278193
  su root syslog
  

  postrotate
      /bin/kill -HUP `cat /var/run/syslogd.pid 2> /dev/null` 2> /dev/null || true
      reload rsyslog >/dev/null 2>&1 || true
  endscript
}
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'root',
  path    => '/etc/logrotate.d/fuel.nodaily',
}

file { '/etc/logrotate.d/puppet':
  group  => 'root',
  mode   => '0644',
  notify => 'Class[Rsyslog::Service]',
  owner  => 'root',
  path   => '/etc/logrotate.d/puppet',
  source => 'puppet:///modules/openstack/logrotate-puppet.conf',
}

file { '/etc/logrotate.d/upstart':
  ensure => 'absent',
  group  => 'syslog',
  mode   => '0640',
  notify => 'Class[Rsyslog::Service]',
  owner  => 'syslog',
  path   => '/etc/logrotate.d/upstart',
}

file { '/etc/rsyslog.conf':
  ensure  => 'file',
  content => '# file is managed by puppet

#################
#### MODULES ####
#################

$ModLoad imuxsock # provides support for local system logging
$ModLoad imklog   # provides kernel logging support (previously done by rklogd) 
#$ModLoad immark  # provides --MARK-- message capability

###########################
#### GLOBAL DIRECTIVES ####
###########################

#
# Set the default permissions for all log files.
#
$FileOwner syslog
$FileGroup syslog
$FileCreateMode 0640
$DirCreateMode 0755
$umask 0000
$PrivDropToUser syslog
$PrivDropToGroup syslog

$MaxMessageSize 32k

#
# Include all config files in /etc/rsyslog.d/
#
$IncludeConfig /etc/rsyslog.d/*.conf

',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'root',
  path    => '/etc/rsyslog.conf',
}

file { '/etc/rsyslog.d/00-remote.conf':
  content => '# file is managed by puppet
#
# Log to remote syslog server
# Templates
# RFC3164 emulation with long tags (32+)
$Template RemoteLog, "<%pri%>%timestamp% %hostname% %syslogtag%%msg:::sp-if-no-1st-sp%%msg%\n"
# RFC5424 emulation would be: "<%pri%>1 %timestamp:::date-rfc3339% %hostname% %syslogtag% %procid% %msgid% %structured-data% %msg%\n"
# Note: don't use %app-name% cuz it would be empty for some cases
$ActionFileDefaultTemplate RemoteLog
$WorkDirectory /var/spool/rsyslog/
#Start remote server 0
$ActionQueueType LinkedList   # use asynchronous processing
$ActionQueueFileName remote0 # set file name, also enables disk mode
$ActionQueueMaxDiskSpace 1g
$ActionQueueSaveOnShutdown on
$ActionQueueLowWaterMark 2000
$ActionQueueHighWaterMark 8000
$ActionQueueSize              1000000       # Reserve 500Mb memory, each queue element is 512b
$ActionQueueDiscardMark       950000        # If the queue looks like filling, start discarding to not block ssh/login/etc.
$ActionQueueDiscardSeverity   0             # When in discarding mode discard everything.
$ActionQueueTimeoutEnqueue    0             # When in discarding mode do not enable throttling.
$ActionQueueDequeueSlowdown 1000
$ActionQueueWorkerThreads 2
$ActionQueueDequeueBatchSize 128
$ActionResumeRetryCount -1


# Isolate sudo logs locally
# match if "program name" is equal to "sudo"
:programname, isequal, "sudo" -/var/log/sudo.log
&~

# Send messages we receive to master node via tcp
# Use an octet-counted framing (understood for rsyslog only) to ensure correct multiline messages delivery
*.* @@(o)10.108.0.2:514;RemoteLog
#End remote server 0

',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'syslog',
  path    => '/etc/rsyslog.d/00-remote.conf',
}

file { '/etc/rsyslog.d/02-ha.conf':
  ensure  => 'present',
  content => '# managed by puppet

### collect HA logs of all levels in /var/log/pacemaker.log
if ($programname == 'lrmd' \
  or $programname == 'pengine' \
  or $programname == 'stonith-ng' \
  or $programname == 'attrd' \
  or $programname == 'cib' \
  or $programname == 'cibadmin' \
  or $programname == 'crmd' \
  or $programname == 'crm_verify' \
  or $programname == 'corosync') \
then -/var/log/pacemaker.log
### stop further processing for the matched entries
& ~
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'syslog',
  path    => '/etc/rsyslog.d/02-ha.conf',
}

file { '/etc/rsyslog.d/03-dashboard.conf':
  ensure  => 'present',
  content => '# managed by puppet

LOCAL1.* -/var/log/dashboard.log
LOCAL1.* ~
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'syslog',
  path    => '/etc/rsyslog.d/03-dashboard.conf',
}

file { '/etc/rsyslog.d/04-mysql.conf':
  ensure  => 'present',
  content => '# managed by puppet

### collect mysql* logs of all levels in /var/log/mysqld.log
if ($programname == 'mysql' \
  or $programname == 'mysqld' \
  or $programname == 'mysqld_safe' \
  or $programname == 'mysql_slow' \
  or $programname == 'mysql-wss') \
then -/var/log/mysqld.log
### stop further processing for the matched entries
& ~

',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'syslog',
  path    => '/etc/rsyslog.d/04-mysql.conf',
}

file { '/etc/rsyslog.d/04-rabbitmq-sasl.conf':
  ensure  => 'file',
  content => '# file is managed by puppet

$ModLoad imfile

$InputFileName /var/log/rabbitmq/rabbit@node-137-sasl.log
$InputFileTag rabbitmq-sasl
$InputFileStateFile state-04-rabbitmq-sasl
$InputFileSeverity NOTICE
$InputFileFacility syslog
$InputFilePollInterval 10
$InputRunFileMonitor
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'root',
  path    => '/etc/rsyslog.d/04-rabbitmq-sasl.conf',
}

file { '/etc/rsyslog.d/04-rabbitmq-shutdown_err.conf':
  ensure  => 'file',
  content => '# file is managed by puppet

$ModLoad imfile

$InputFileName /var/log/rabbitmq/shutdown_err
$InputFileTag rabbitmq-shutdown_err
$InputFileStateFile state-04-rabbitmq-shutdown_err
$InputFileSeverity ERROR
$InputFileFacility syslog
$InputFilePollInterval 10
$InputRunFileMonitor
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'root',
  path    => '/etc/rsyslog.d/04-rabbitmq-shutdown_err.conf',
}

file { '/etc/rsyslog.d/04-rabbitmq-startup_err.conf':
  ensure  => 'file',
  content => '# file is managed by puppet

$ModLoad imfile

$InputFileName /var/log/rabbitmq/startup_err
$InputFileTag rabbitmq-startup_err
$InputFileStateFile state-04-rabbitmq-startup_err
$InputFileSeverity ERROR
$InputFileFacility syslog
$InputFilePollInterval 10
$InputRunFileMonitor
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'root',
  path    => '/etc/rsyslog.d/04-rabbitmq-startup_err.conf',
}

file { '/etc/rsyslog.d/04-rabbitmq.conf':
  ensure  => 'file',
  content => '# file is managed by puppet

$ModLoad imfile

$InputFileName /var/log/rabbitmq/rabbit@node-137.log
$InputFileTag rabbitmq
$InputFileStateFile state-04-rabbitmq
$InputFileSeverity NOTICE
$InputFileFacility syslog
$InputFilePollInterval 10
$InputRunFileMonitor
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'root',
  path    => '/etc/rsyslog.d/04-rabbitmq.conf',
}

file { '/etc/rsyslog.d/05-apache2-error.conf':
  ensure  => 'file',
  content => '# file is managed by puppet

$ModLoad imfile

$InputFileName /var/log/apache2/error.log
$InputFileTag apache2_error
$InputFileStateFile state-05-apache2-error
$InputFileSeverity ERROR
$InputFileFacility syslog
$InputFilePollInterval 10
$InputRunFileMonitor
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'root',
  path    => '/etc/rsyslog.d/05-apache2-error.conf',
}

file { '/etc/rsyslog.d/10-nova.conf':
  ensure  => 'present',
  content => '# managed by puppet

:syslogtag, contains, "nova" -/var/log/nova-all.log
& ~
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'syslog',
  path    => '/etc/rsyslog.d/10-nova.conf',
}

file { '/etc/rsyslog.d/11-horizon_access.conf':
  ensure  => 'file',
  content => '# file is managed by puppet

$ModLoad imfile

$InputFileName /var/log/apache2/horizon_access.log
$InputFileTag horizon_access
$InputFileStateFile state-11-horizon_access
$InputFileSeverity INFO
$InputFileFacility syslog
$InputFilePollInterval 10
$InputRunFileMonitor
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'root',
  path    => '/etc/rsyslog.d/11-horizon_access.conf',
}

file { '/etc/rsyslog.d/11-horizon_error.conf':
  ensure  => 'file',
  content => '# file is managed by puppet

$ModLoad imfile

$InputFileName /var/log/apache2/horizon_error.log
$InputFileTag horizon_error
$InputFileStateFile state-11-horizon_error
$InputFileSeverity ERROR
$InputFileFacility syslog
$InputFilePollInterval 10
$InputRunFileMonitor
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'root',
  path    => '/etc/rsyslog.d/11-horizon_error.conf',
}

file { '/etc/rsyslog.d/12-keystone_wsgi_admin_access.conf':
  ensure  => 'file',
  content => '# file is managed by puppet

$ModLoad imfile

$InputFileName /var/log/apache2/keystone_wsgi_admin_access.log
$InputFileTag keystone_wsgi_admin_access
$InputFileStateFile state-12-keystone_wsgi_admin_access
$InputFileSeverity INFO
$InputFileFacility syslog
$InputFilePollInterval 10
$InputRunFileMonitor
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'root',
  path    => '/etc/rsyslog.d/12-keystone_wsgi_admin_access.conf',
}

file { '/etc/rsyslog.d/12-keystone_wsgi_admin_error.conf':
  ensure  => 'file',
  content => '# file is managed by puppet

$ModLoad imfile

$InputFileName /var/log/apache2/keystone_wsgi_admin_error.log
$InputFileTag keystone_wsgi_admin_error
$InputFileStateFile state-12-keystone_wsgi_admin_error
$InputFileSeverity ERROR
$InputFileFacility syslog
$InputFilePollInterval 10
$InputRunFileMonitor
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'root',
  path    => '/etc/rsyslog.d/12-keystone_wsgi_admin_error.conf',
}

file { '/etc/rsyslog.d/13-keystone_wsgi_main_access.conf':
  ensure  => 'file',
  content => '# file is managed by puppet

$ModLoad imfile

$InputFileName /var/log/apache2/keystone_wsgi_main_access.log
$InputFileTag keystone_wsgi_main_access
$InputFileStateFile state-13-keystone_wsgi_main_access
$InputFileSeverity INFO
$InputFileFacility syslog
$InputFilePollInterval 10
$InputRunFileMonitor
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'root',
  path    => '/etc/rsyslog.d/13-keystone_wsgi_main_access.conf',
}

file { '/etc/rsyslog.d/13-keystone_wsgi_main_error.conf':
  ensure  => 'file',
  content => '# file is managed by puppet

$ModLoad imfile

$InputFileName /var/log/apache2/keystone_wsgi_main_error.log
$InputFileTag keystone_wsgi_main_error
$InputFileStateFile state-13-keystone_wsgi_main_error
$InputFileSeverity ERROR
$InputFileFacility syslog
$InputFilePollInterval 10
$InputRunFileMonitor
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'root',
  path    => '/etc/rsyslog.d/13-keystone_wsgi_main_error.conf',
}

file { '/etc/rsyslog.d/20-keystone.conf':
  ensure  => 'present',
  content => '# managed by puppet

:syslogtag, contains, "keystone" -/var/log/keystone-all.log
& ~
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'syslog',
  path    => '/etc/rsyslog.d/20-keystone.conf',
}

file { '/etc/rsyslog.d/30-cinder.conf':
  ensure  => 'present',
  content => '# managed by puppet

:syslogtag, contains, "cinder" -/var/log/cinder-all.log
& ~
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'syslog',
  path    => '/etc/rsyslog.d/30-cinder.conf',
}

file { '/etc/rsyslog.d/40-glance.conf':
  ensure  => 'present',
  content => '# managed by puppet

:syslogtag, contains, "glance" -/var/log/glance-all.log
& ~
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'syslog',
  path    => '/etc/rsyslog.d/40-glance.conf',
}

file { '/etc/rsyslog.d/50-neutron.conf':
  ensure  => 'present',
  content => '# managed by puppet

:syslogtag, contains, "neutron" -/var/log/neutron-all.log
& ~
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'syslog',
  path    => '/etc/rsyslog.d/50-neutron.conf',
}

file { '/etc/rsyslog.d/51-ceilometer.conf':
  ensure  => 'present',
  content => '# managed by puppet

:syslogtag, contains, "ceilometer" -/var/log/ceilometer-all.log
&~
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'syslog',
  path    => '/etc/rsyslog.d/51-ceilometer.conf',
}

file { '/etc/rsyslog.d/52-sahara.conf':
  ensure  => 'present',
  content => '# managed by puppet

:syslogtag, contains, "sahara" -/var/log/sahara-all.log
& ~
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'syslog',
  path    => '/etc/rsyslog.d/52-sahara.conf',
}

file { '/etc/rsyslog.d/53-murano.conf':
  ensure  => 'present',
  content => '# managed by puppet

:syslogtag, contains, "murano" -/var/log/murano-all.log
### stop further processing for the matched entries
& ~
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'syslog',
  path    => '/etc/rsyslog.d/53-murano.conf',
}

file { '/etc/rsyslog.d/54-heat.conf':
  ensure  => 'present',
  content => '# managed by puppet

:syslogtag, contains, "heat" -/var/log/heat-all.log
& ~
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'syslog',
  path    => '/etc/rsyslog.d/54-heat.conf',
}

file { '/etc/rsyslog.d/60-puppet-apply.conf':
  content => '# file is managed by puppet

### collect puppet logs of all levels in /var/log/puppet/puppet.log
if ($programname == 'puppet-apply' \
 or $programname == 'puppet-user' \
 or $programname == 'puppet-error') \
then -/var/log/puppet/puppet.log
### stop further processing for the matched entries
& ~
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'syslog',
  path    => '/etc/rsyslog.d/60-puppet-apply.conf',
}

file { '/etc/rsyslog.d/61-mco-nailgun-agent.conf':
  content => '# managed by puppet

### drop duplicating mcollective/nailgun-agent messages
if ($programname == 'mcollective' or \
  $programname == 'nailgun-agent' ) \
then ~
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'syslog',
  path    => '/etc/rsyslog.d/61-mco-nailgun-agent.conf',
}

file { '/etc/rsyslog.d/61-mco_agent_debug.conf':
  ensure  => 'file',
  content => '# file is managed by puppet

$ModLoad imfile

$InputFileName /var/log/mcollective.log
$InputFileTag mcollective
$InputFileStateFile state-61-mco_agent_debug
$InputFileSeverity DEBUG
$InputFileFacility daemon
$InputFilePollInterval 10
$InputRunFileMonitor
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'root',
  path    => '/etc/rsyslog.d/61-mco_agent_debug.conf',
}

file { '/etc/rsyslog.d/62-mongod.conf':
  content => ':syslogtag, contains, "mongod" -/var/log/mongod.log

### stop further processing for the matched entries
& ~
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'syslog',
  path    => '/etc/rsyslog.d/62-mongod.conf',
}

file { '/etc/rsyslog.d/80-swift.conf':
  content => '# managed by puppet

:syslogtag, contains, "swift" -/var/log/swift-all.log
& ~
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'syslog',
  path    => '/etc/rsyslog.d/80-swift.conf',
}

file { '/etc/rsyslog.d/90-local.conf':
  content => '# file is managed by puppet
#

# Log auth messages locally
auth,authpriv.*                 /var/log/auth.log

# First some standard log files.  Log by facility.
#
# Skip duplicates - all common debug, info, notice, warn go to
# debug & messages files respectively; others should go to syslog
#
*.error;auth,authpriv.none     -/var/log/syslog
cron.*                          /var/log/cron.log
daemon.*                       -/var/log/daemon.log
# Do not send info to kern.log - it duplicates messages
kern.*;kern.!=info             -/var/log/kern.log
#lpr.*                          -/var/log/lpr.log
mail.*                         -/var/log/mail.log
user.*                         -/var/log/user.log

#
# Logging for the mail system.  Split it up so that
# it is easy to write scripts to parse these files.
#
mail.info                      -/var/log/mail.info
mail.warn                      -/var/log/mail.warn
mail.err                        /var/log/mail.err

#
# Logging for INN news system.
#
news.crit                       /var/log/news/news.crit
news.err                        /var/log/news/news.err
news.notice                     -/var/log/news/news.notice

#
# Some "catch-all" log files.
#
*.=debug;\
       auth,authpriv.none;\
       news.none;mail.none     -/var/log/debug
*.=info;*.=notice;*.=warn;\
       auth,authpriv.none;\
       cron,daemon.none;\
       mail,news.none          -/var/log/messages

#
# I like to have messages displayed on the console, but only on a virtual
# console I usually leave idle.
#
#daemon,mail.*;\
#       news.=crit;news.=err;news.=notice;\
#       *.=debug;*.=info;\
#       *.=notice;*.=warn       /dev/tty8

# The named pipe /dev/xconsole is for the `xconsole' utility.  To use it,
# you must invoke `xconsole' with the `-file' option:
#
#    $ xconsole -file /dev/xconsole [...]
#
# NOTE: adjust the list below, or you'll go crazy if you have a reasonably
#      busy site..
#
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'syslog',
  path    => '/etc/rsyslog.d/90-local.conf',
}

file { '/etc/rsyslog.d/':
  ensure  => 'directory',
  force   => 'true',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'root',
  path    => '/etc/rsyslog.d',
  purge   => 'true',
  recurse => 'true',
}

file { '/etc/rsyslog.d/client.conf':
  ensure  => 'present',
  content => '# file is managed by puppet

$EscapeControlCharactersOnReceive off

# Load UDP module, required since Openstack Juno (#1385295)
$ModLoad imudp
$UDPServerRun 514

#
# Disk-Assisted Memory Queues, async writes, no escape chars
#
$OMFileASyncWriting on
$MainMsgQueueType LinkedList
$WorkDirectory /var/spool/rsyslog/
$MainMsgQueueFileName mainmsgqueue
$MainMsgQueueSaveOnShutdown on
$MainMsgQueueDequeueSlowdown 1000
$MainMsgQueueWorkerThreads 2
$MainMsgQueueDequeueBatchSize 128
$SystemLogRateLimitInterval 0   # disable rate limits for rsyslog
',
  group   => 'syslog',
  mode    => '0640',
  notify  => 'Class[Rsyslog::Service]',
  owner   => 'root',
  path    => '/etc/rsyslog.d/client.conf',
  require => 'File[/etc/rsyslog.d/]',
}

file { '/var/lib/rsyslog':
  ensure => 'directory',
  group  => 'syslog',
  mode   => '0640',
  notify => 'Class[Rsyslog::Service]',
  owner  => 'root',
  path   => '/var/lib/rsyslog',
}

file { '/var/log':
  group => 'syslog',
  mode  => '0775',
  owner => 'root',
  path  => '/var/log',
}

file { '/var/spool/rsyslog/':
  ensure => 'directory',
  group  => 'syslog',
  mode   => '0640',
  notify => 'Class[Rsyslog::Service]',
  owner  => 'root',
  path   => '/var/spool/rsyslog',
}

file_line { 'logrotate-compress':
  ensure => 'present',
  after  => '^tabooext',
  before => 'File_line[logrotate-delaycompress]',
  line   => 'compress',
  match  => '^compress',
  name   => 'logrotate-compress',
  path   => '/etc/logrotate.conf',
}

file_line { 'logrotate-delaycompress':
  ensure => 'present',
  after  => '^compress',
  before => 'File_line[logrotate-minsize]',
  line   => 'delaycompress',
  match  => '^delaycompress',
  name   => 'logrotate-delaycompress',
  path   => '/etc/logrotate.conf',
}

file_line { 'logrotate-maxsize':
  ensure => 'present',
  after  => '^minsize',
  line   => 'maxsize 100M',
  match  => '^maxsize',
  name   => 'logrotate-maxsize',
  path   => '/etc/logrotate.conf',
}

file_line { 'logrotate-minsize':
  ensure => 'present',
  after  => '^delaycompress',
  before => 'File_line[logrotate-maxsize]',
  line   => 'minsize 10M',
  match  => '^minsize',
  name   => 'logrotate-minsize',
  path   => '/etc/logrotate.conf',
}

file_line { 'logrotate-tabooext':
  ensure => 'present',
  after  => '^create',
  before => 'File_line[logrotate-compress]',
  line   => 'tabooext + .nodaily',
  match  => '^tabooext',
  name   => 'logrotate-tabooext',
  path   => '/etc/logrotate.conf',
}

package { 'anacron':
  ensure => 'installed',
  name   => 'anacron',
}

package { 'cron':
  ensure => 'installed',
  name   => 'cron',
}

package { 'rsyslog':
  ensure => 'installed',
  name   => 'rsyslog',
}

rsyslog::imfile { '04-rabbitmq-sasl':
  file_facility    => 'syslog',
  file_name        => '/var/log/rabbitmq/rabbit@node-137-sasl.log',
  file_severity    => 'NOTICE',
  file_tag         => 'rabbitmq-sasl',
  name             => '04-rabbitmq-sasl',
  polling_interval => '10',
  run_file_monitor => 'true',
}

rsyslog::imfile { '04-rabbitmq-shutdown_err':
  file_facility    => 'syslog',
  file_name        => '/var/log/rabbitmq/shutdown_err',
  file_severity    => 'ERROR',
  file_tag         => 'rabbitmq-shutdown_err',
  name             => '04-rabbitmq-shutdown_err',
  polling_interval => '10',
  run_file_monitor => 'true',
}

rsyslog::imfile { '04-rabbitmq-startup_err':
  file_facility    => 'syslog',
  file_name        => '/var/log/rabbitmq/startup_err',
  file_severity    => 'ERROR',
  file_tag         => 'rabbitmq-startup_err',
  name             => '04-rabbitmq-startup_err',
  polling_interval => '10',
  run_file_monitor => 'true',
}

rsyslog::imfile { '04-rabbitmq':
  file_facility    => 'syslog',
  file_name        => '/var/log/rabbitmq/rabbit@node-137.log',
  file_severity    => 'NOTICE',
  file_tag         => 'rabbitmq',
  name             => '04-rabbitmq',
  polling_interval => '10',
  run_file_monitor => 'true',
}

rsyslog::imfile { '05-apache2-error':
  file_facility    => 'syslog',
  file_name        => '/var/log/apache2/error.log',
  file_severity    => 'ERROR',
  file_tag         => 'apache2_error',
  name             => '05-apache2-error',
  polling_interval => '10',
  run_file_monitor => 'true',
}

rsyslog::imfile { '11-horizon_access':
  file_facility    => 'syslog',
  file_name        => '/var/log/apache2/horizon_access.log',
  file_severity    => 'INFO',
  file_tag         => 'horizon_access',
  name             => '11-horizon_access',
  polling_interval => '10',
  run_file_monitor => 'true',
}

rsyslog::imfile { '11-horizon_error':
  file_facility    => 'syslog',
  file_name        => '/var/log/apache2/horizon_error.log',
  file_severity    => 'ERROR',
  file_tag         => 'horizon_error',
  name             => '11-horizon_error',
  polling_interval => '10',
  run_file_monitor => 'true',
}

rsyslog::imfile { '12-keystone_wsgi_admin_access':
  file_facility    => 'syslog',
  file_name        => '/var/log/apache2/keystone_wsgi_admin_access.log',
  file_severity    => 'INFO',
  file_tag         => 'keystone_wsgi_admin_access',
  name             => '12-keystone_wsgi_admin_access',
  polling_interval => '10',
  run_file_monitor => 'true',
}

rsyslog::imfile { '12-keystone_wsgi_admin_error':
  file_facility    => 'syslog',
  file_name        => '/var/log/apache2/keystone_wsgi_admin_error.log',
  file_severity    => 'ERROR',
  file_tag         => 'keystone_wsgi_admin_error',
  name             => '12-keystone_wsgi_admin_error',
  polling_interval => '10',
  run_file_monitor => 'true',
}

rsyslog::imfile { '13-keystone_wsgi_main_access':
  file_facility    => 'syslog',
  file_name        => '/var/log/apache2/keystone_wsgi_main_access.log',
  file_severity    => 'INFO',
  file_tag         => 'keystone_wsgi_main_access',
  name             => '13-keystone_wsgi_main_access',
  polling_interval => '10',
  run_file_monitor => 'true',
}

rsyslog::imfile { '13-keystone_wsgi_main_error':
  file_facility    => 'syslog',
  file_name        => '/var/log/apache2/keystone_wsgi_main_error.log',
  file_severity    => 'ERROR',
  file_tag         => 'keystone_wsgi_main_error',
  name             => '13-keystone_wsgi_main_error',
  polling_interval => '10',
  run_file_monitor => 'true',
}

rsyslog::imfile { '61-mco_agent_debug':
  file_facility    => 'daemon',
  file_name        => '/var/log/mcollective.log',
  file_severity    => 'DEBUG',
  file_tag         => 'mcollective',
  name             => '61-mco_agent_debug',
  polling_interval => '10',
  run_file_monitor => 'true',
}

service { 'rsyslog':
  ensure  => 'running',
  enable  => 'true',
  name    => 'rsyslog',
  require => 'Class[Rsyslog::Config]',
}

stage { 'main':
  name => 'main',
}

