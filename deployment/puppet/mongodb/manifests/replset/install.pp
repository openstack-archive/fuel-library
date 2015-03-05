# PRIVATE CLASS: do not call directly
class mongodb::replset::install (
    $replset_members = $mongodb::replset::replset_members,
)

{
  Exec{
    logoutput => true,
    path => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin',
  }

  notify { 'Create ReplicaSet ': }

  define add_replset_members() {
    $node_hostname = $name
    notify { "Member ${node_hostname}":; }
    exec { "add ${node_hostname}":
      command   => "/bin/echo  \"rs.add(\\\"${node_hostname}\\\")\"| /usr/bin/mongo",
    }
  }

# Workaround: wait for server
  exec { 'wait_for_server':
    command => "/bin/echo \" for TRY_NUMBER in \`seq 1 10\`; do /bin/echo \\\"Connecting to mongo...\\\"$TRY_NUMBER; (/bin/echo \\\"show dbs;\\\" | /usr/bin/mongo )&& break; sleep 5; done\" | /bin/bash",
    tries     => 10,
    try_sleep => 1,
  } ->

  exec { 'rs.initiate':
    command   => '/bin/echo "rs.initiate()"| /usr/bin/mongo',
  } ->

  exec { 'do_pause_1':
    command   => '/bin/sleep 5',
  } ->

  exec { 'rs.conf':
    command   => '/bin/echo "rs.conf()"| /usr/bin/mongo',
  } ->

  exec { 'do_pause_2':
    command   => '/bin/sleep 5',
  } ->
  add_replset_members{ $replset_members:; }

}
