## proj_name       => isolated configuration for project
## templatehost    => checks,intervals parameters for hosts (as Hash)
# name - name of this template
# check_interval check command interval for hosts included in this group
## templateservice => checks,intervals parameters for services (as Hash)
# name - name of this template
# check_interval check command interval for services included in this group
## hostgroups      =>  create hostgroups
# Put all hostgroups from nrpe here (as Array)
class {'nagios::master':
  proj_name       => 'test',
  templatehost    => {'name' => 'default-host','check_interval' => '10'},
  templateservice => {'name' => 'default-service' ,'check_interval'=>'10'},
  hostgroups      => ['compute','controller'],
  contactgroups   => {'group' => 'admins', 'alias' => 'Admins'},
  contacts        => {'user' => 'hotkey', 'alias' => 'Dennis Hoppe',
               'email' => 'nagios@%{domain}',
               'group' => 'admins'},
}
