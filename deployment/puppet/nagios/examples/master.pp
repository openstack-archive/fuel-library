class {'nagios::master':
  proj_name       => 'test',
  templatehost    => 'default-host',
  templateservice => 'default-service',
  hostgroups      => ['compute','controller'],
  contactgroups   => {'group' => 'admins', 'alias' => 'Admins'},
  contacts        => {'user' => 'hotkey', 'alias' => 'Dennis Hoppe',
               'email' => 'nagios@%{domain}',
               'group' => 'admins'},
}
