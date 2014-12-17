exec {'create-m1.micro-flavor':
  command => "bash -c \"source /root/openrc; nova flavor-create --is-public true m1.micro auto 64 0 1\"",
  path    => '/sbin:/usr/sbin:/bin:/usr/bin',
  unless  => 'bash -c "source /root/openrc; nova flavor-list | grep -q m1.micro"',
}
