#class mysql::replicator (
# Not used because we need to start mysql for the first time 
# with corosync with init script to create users
#  database_user { "${user}@${name}":
#    password_hash => mysql_password($password),
#    provider => 'mysql',
#  }
#  database_grant { "${user}@${name}":
#    privileges => ['Super_priv'],
#    provider => 'mysql',
#    require => Database_user["${user}@${name}"]
#  }
#}
