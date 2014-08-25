define corosync::resource (
  $ensure = 'present',
  $primitive_class = 'ocf',
  $primitive_type = undef,
  $provided_by = undef,
  $cib = undef,
  $parameters = undef,
  $operations = undef,
  $metadata = undef,
  $ms_metadata = undef,
  $multistate_hash = undef,
  $use_handler = true,
) {

  cs_resource { $title :
    ensure          => $ensure,
    primitive_class => $primitive_class,
    primitive_type  => $primitive_type,
    provided_by     => $provided_by,
    cib             => $cib,
    parameters      => $parameters,
    operations      => $operations,
    metadata        => $metadata,
    ms_metadata     => $ms_metadata,
    multistate_hash => $multistate_hash,
  }

  if ($primitive_class == 'ocf') and ($use_handler) {
    $ocf_root = '/usr/lib/ocf'
    $handler_root = '/usr/local/bin'
    $ocf_file = "${ocf_root}/resource.d/${provided_by}/${primitive_type}"
    $hadler_name = "${handler_root}/ocf_${title}"
    file { $hadler_name :
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
      content => template('corosync/ocf_handler.erb'),
    }
  }
}
