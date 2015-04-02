notice('MODULAR: zabbix-server.pp')

class { 'zabbix::server' :}

###################################

class mysql::server {}
class { 'mysql::server' :}
