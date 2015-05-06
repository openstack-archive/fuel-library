# PRIVATE CLASS: do not call directly
class mongodb::replset::install (
    $replset_members = $mongodb::replset::replset_members,
    $admin_password  = undef,
)

{
  Exec{
    logoutput => true,
    path => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin',
  }

  notify { 'Create ReplicaSet ': }

  define add_replset_members(
    $admin_password = undef ) {
    $node_hostname = $name
    notify { "Member ${node_hostname}":; }
    exec { "add ${node_hostname}":
      command  => "/bin/echo  \"rs.add(\\\"${node_hostname}\\\")\"| /usr/bin/mongo -u admin -p ${admin_password} admin",
      unless   => "/usr/bin/mongo --eval \"printjson(rs.add(\\\"${node_hostname}\\\"))\"",
    }
  }

# Workaround: wait for server
  exec { 'wait_for_server':
    command   => 'echo \'TRY_NUMBER=1; for i in {1..10}; do echo "Connecting to mongo... $TRY_NUMBER"; (mongostat -n1 | egrep "(ok|REC)" ) && break; sleep 1; ((TRY_NUMBER++)); done\' | bash',
    tries     => 10,
    try_sleep => 1,
  } ->

  exec { 'rs.initiate':
    command => '/bin/echo "rs.initiate()"| /usr/bin/mongo',
    onlyif  => '/bin/echo "rs.status()"| /usr/bin/mongo | grep -q "run rs.initiate(...) if not yet done for the set"',
  } ->

  exec { 'rs.conf':
    command   => '/bin/echo "rs.conf()"| /usr/bin/mongo',
  } ->

  exec {"wait_for_elections":
    command   => 'echo "db.isMaster()" | /usr/bin/mongo | grep ismaster | grep -q true',
    tries     => 40,
    try_sleep => 3,
    provider  => 'shell',
  } ->

  add_replset_members{ $replset_members:
    admin_password => $admin_password,
  }

}
