# Class: limits
#
# Class responsible for concatenating the limits fragments.
#
# Parameters:
#  - final file to be written to
#
# Actions:
#   
class limits(
  $limits_file = '/etc/security/limits.conf'
) {

  $fragments_dir = '/etc/puppet/tmp/limits_fragments.d/'
  $tmp_limits_conf = '/etc/puppet/tmp/limits.conf'

  file { [ '/etc/puppet/tmp', $fragments_dir ]:
    ensure  => directory,
    recurse => true,
    purge   => true,
    owner   => 'puppet',
    group   => 'puppet',
    mode    =>  '600',
  }
  exec { 'cp_limits':
    command => "/bin/cp ${tmp_limits_conf} ${limits_file}",
    onlyif  => "/bin/cat ${fragments_dir}/* > ${tmp_limits_conf} && ! diff ${tmp_limits_conf} ${limits_file}",
    require => File[$fragments_dir]
  }

  file { $limits_file:
    owner => 'root',
    group => 'root',
    mode => '0644',
    require => Exec['cp_limits']
  }
}
