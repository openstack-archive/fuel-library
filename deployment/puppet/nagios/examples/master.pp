## proj_name       => isolated configuration for project
## templatehost    => checks,intervals parameters for hosts (as Hash)
# name - name of this template
# check_interval check command interval for hosts included in this group
# official site quote:
# "Important: The default value for this is set to 60, which means that a "unit value" of 1 in the object configuration file will mean 60 seconds (1 minute). I have not really tested other values for this variable, so proceed at your own risk if you decide to do so!"

## templateservice => checks,intervals parameters for services (as Hash)
# name - name of this template
# check_interval check command interval for services included in this group
## hostgroups      =>  create hostgroups
# Put all hostgroups from nrpe here (as Array)

node default {
  class {'nagios::master':
    proj_name       => 'test',
    rabbitmq        => true,
    nginx           => false,
    mysql_user      => 'root',
    mysql_pass      => 'nova',
    mysql_port      => '3307',
    rabbit_user     => 'nova',
    rabbit_pass     => 'nova',
    rabbit_port     => '5673',
    templatehost    => {'name' => 'default-host', 'check_interval' => '10'},
    templateservice => {'name' => 'default-service', 'check_interval'=>'10'},
    hostgroups      => ['compute', 'controller', 'swift-storage', 'swift-proxy'],
    contactgroups   => {'group' => 'admins', 'alias' => 'Admins'},
    contacts        => {'user' => 'hotkey', 'alias' => 'Dennis Hoppe',
                 'email' => 'nagios@%{domain}',
                 'group' => 'admins'},
  }
}
