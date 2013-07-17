class { 'limits':
  limits_file => '/tmp/limits.conf'
}
limits::fragment { 'joe/soft/nproc':
  value => '10'
}
limits::fragment { 'dan/soft/nproc':
  value => '10'
}
#limits::fragment { 'bob/hard/nproc':
#  value => '10'
#}
