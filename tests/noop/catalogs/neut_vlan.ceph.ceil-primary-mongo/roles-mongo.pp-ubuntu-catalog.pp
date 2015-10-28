anchor { 'mongodb::server::end':
  name => 'mongodb::server::end',
}

anchor { 'mongodb::server::start':
  before => 'Class[Mongodb::Server::Install]',
  name   => 'mongodb::server::start',
}

class { 'Mongodb::Client::Install':
  name => 'Mongodb::Client::Install',
}

class { 'Mongodb::Client':
  ensure => '2.6.10',
  before => 'Firewall[120 mongodb]',
  name   => 'Mongodb::Client',
}

class { 'Mongodb::Globals':
  before  => 'Notify[MongoDB params: 127.0.0.1192.168.0.1]',
  name    => 'Mongodb::Globals',
  version => '2.6.10',
}

class { 'Mongodb::Params':
  name => 'Mongodb::Params',
}

class { 'Mongodb::Replset':
  before => 'Mongodb_user[admin]',
  name   => 'Mongodb::Replset',
  sets   => {'ceilometer' => {'auth_enabled' => 'true', 'members' => ['192.168.0.1:27017']}},
}

class { 'Mongodb::Server::Config':
  before => 'Class[Mongodb::Server::Service]',
  name   => 'Mongodb::Server::Config',
}

class { 'Mongodb::Server::Install':
  before => 'Class[Mongodb::Server::Config]',
  name   => 'Mongodb::Server::Install',
}

class { 'Mongodb::Server::Service':
  before => 'Anchor[mongodb::server::end]',
  name   => 'Mongodb::Server::Service',
}

class { 'Mongodb::Server':
  ensure           => 'true',
  auth             => 'true',
  before           => ['Mongodb_user[admin]', 'Class[Mongodb::Replset]'],
  bind_ip          => ['127.0.0.1', '192.168.0.1'],
  config           => '/etc/mongodb.conf',
  dbpath           => '/var/lib/mongo/mongodb',
  directoryperdb   => 'true',
  fork             => 'false',
  group            => 'mongodb',
  journal          => 'true',
  key              => 'key',
  keyfile          => '/etc/mongodb.key',
  logappend        => 'true',
  logpath          => 'false',
  name             => 'Mongodb::Server',
  oplog_size       => '10240',
  package_ensure   => 'true',
  package_name     => 'mongodb-server',
  port             => '27017',
  profile          => '1',
  replset          => 'ceilometer',
  service_enable   => 'true',
  service_ensure   => 'running',
  service_name     => 'mongodb',
  service_provider => 'upstart',
  syslog           => 'true',
  user             => 'mongodb',
  verbose          => 'false',
  verbositylevel   => 'v',
}

class { 'Openstack::Mongo':
  auth                       => 'true',
  ceilometer_database        => 'ceilometer',
  ceilometer_db_password     => 'Toe5phw4',
  ceilometer_metering_secret => 'tHq2rcoq',
  ceilometer_replset_members => '192.168.0.1',
  ceilometer_user            => 'ceilometer',
  dbpath                     => '/var/lib/mongo/mongodb',
  debug                      => 'false',
  directoryperdb             => 'true',
  fork                       => 'false',
  journal                    => 'true',
  keyfile                    => '/etc/mongodb.key',
  logappend                  => 'true',
  mongo_version              => '2.6.10',
  mongodb_bind_address       => ['127.0.0.1', '192.168.0.1'],
  mongodb_port               => '27017',
  name                       => 'Openstack::Mongo',
  oplog_size                 => '10240',
  profile                    => '1',
  replset_name               => 'ceilometer',
  use_syslog                 => 'true',
  verbose                    => 'false',
}

class { 'Settings':
  name => 'Settings',
}

class { 'Sysctl::Base':
  name => 'Sysctl::Base',
}

class { 'main':
  name => 'main',
}

file { '/etc/mongodb.conf':
  content => '# mongo.conf - generated from Puppet

# System Log

systemLog.destination: syslog
systemLog.quiet: true
systemLog.verbosity: 1

#Process Management

#Storage
storage.dbPath: /var/lib/mongo/mongodb
storage.journal.enabled: true
storage.directoryPerDB: true


#Security
security.authorization: enabled
security.keyFile: /etc/mongodb.key


# Net
net.bindIp:  127.0.0.1,192.168.0.1
net.port: 27017

#Replication
replication.replSetName: ceilometer
replication.oplogSizeMB: 10240

#Operation Profiling
operationProfiling.mode: slowOp


',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Mongodb::Server::Service]',
  owner   => 'root',
  path    => '/etc/mongodb.conf',
}

file { '/etc/mongodb.key':
  content => 'key',
  group   => 'mongodb',
  mode    => '0400',
  owner   => 'mongodb',
  path    => '/etc/mongodb.key',
}

file { '/etc/sysctl.conf':
  ensure => 'present',
  group  => '0',
  mode   => '0644',
  owner  => 'root',
  path   => '/etc/sysctl.conf',
}

file { '/var/lib/mongo/mongodb':
  ensure  => 'directory',
  group   => 'mongodb',
  mode    => '0755',
  owner   => 'mongodb',
  path    => '/var/lib/mongo/mongodb',
  require => 'File[/etc/mongodb.conf]',
}

file { 'mongorc':
  ensure  => 'present',
  before  => 'Class[Mongodb::Globals]',
  content => 'function authRequired() {
  try {
    if (db.serverCmdLineOpts().code == 13) {
      return true;
    }
    return false;
  }
  catch (err) {
    return false;
  }
}

if (authRequired()) {
  try {
    var prev_db = db
    db = db.getSiblingDB('admin')
    db.auth('admin', 'Toe5phw4')
    db = db.getSiblingDB(prev_db)
  }
  catch (err) {
    // This isn't catching authentication errors as I'd expect...
    return;
  }
}
',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/root/.mongorc.js',
}

firewall { '120 mongodb':
  action => 'accept',
  before => 'Class[Mongodb::Server]',
  name   => '120 mongodb',
  port   => '27017',
  proto  => 'tcp',
}

mongodb::db { 'ceilometer':
  before        => 'Notify[mongodb finished]',
  name          => 'ceilometer',
  password      => 'Toe5phw4',
  password_hash => 'false',
  roles         => ['readWrite', 'dbAdmin'],
  tries         => '10',
  user          => 'ceilometer',
}

mongodb_conn_validator { 'mongodb':
  name    => 'mongodb',
  port    => '27017',
  require => 'Service[mongodb]',
  server  => ['127.0.0.1', '192.168.0.1'],
  timeout => '240',
}

mongodb_database { 'ceilometer':
  ensure  => 'present',
  name    => 'ceilometer',
  require => 'Class[Mongodb::Server]',
  tries   => '10',
}

mongodb_replset { 'ceilometer':
  auth_enabled => 'true',
  members      => '192.168.0.1:27017',
  name         => 'ceilometer',
}

mongodb_user { 'admin':
  ensure        => 'present',
  before        => 'Notify[mongodb configuring ceilometer database]',
  database      => 'admin',
  name          => 'admin',
  password_hash => '483849a689e268a1597f5524214f4293',
  roles         => ['userAdmin', 'readWrite', 'dbAdmin', 'dbAdminAnyDatabase', 'readAnyDatabase', 'readWriteAnyDatabase', 'userAdminAnyDatabase', 'clusterAdmin', 'clusterManager', 'clusterMonitor', 'hostManager', 'root', 'restore'],
  tag           => 'admin',
  tries         => '10',
  username      => 'admin',
}

mongodb_user { 'ceilometer':
  ensure        => 'present',
  database      => 'ceilometer',
  name          => 'ceilometer',
  password_hash => '80a8d660c80cf564f557ccee90ce9ae5',
  require       => 'Mongodb_database[ceilometer]',
  roles         => ['readWrite', 'dbAdmin'],
}

notify { 'MongoDB params: 127.0.0.1192.168.0.1':
  before => 'Class[Mongodb::Client]',
  name   => 'MongoDB params: 127.0.0.1192.168.0.1',
}

notify { 'mongodb configuring ceilometer database':
  before => 'Mongodb::Db[ceilometer]',
  name   => 'mongodb configuring ceilometer database',
}

notify { 'mongodb finished':
  name => 'mongodb finished',
}

package { 'mongodb_server':
  ensure => 'present',
  name   => 'mongodb-server',
  tag    => 'mongodb',
}

service { 'mongodb':
  ensure    => 'true',
  enable    => 'true',
  hasstatus => 'true',
  name      => 'mongodb',
  provider  => 'upstart',
}

stage { 'main':
  name => 'main',
}

sysctl::value { 'net.ipv4.tcp_keepalive_time':
  key     => 'net.ipv4.tcp_keepalive_time',
  name    => 'net.ipv4.tcp_keepalive_time',
  require => 'Class[Sysctl::Base]',
  value   => '300',
}

sysctl { 'net.ipv4.tcp_keepalive_time':
  before => 'Sysctl_runtime[net.ipv4.tcp_keepalive_time]',
  name   => 'net.ipv4.tcp_keepalive_time',
  val    => '300',
}

sysctl_runtime { 'net.ipv4.tcp_keepalive_time':
  name => 'net.ipv4.tcp_keepalive_time',
  val  => '300',
}

