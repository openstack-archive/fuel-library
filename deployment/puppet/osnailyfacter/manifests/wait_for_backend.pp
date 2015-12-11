class osnailyfacter::wait_for_backend (
  $backends_list = [],
  $provider = 'haproxy',
  $url
)
{

  haproxy_backend_status { $backends_list :
    provider => $provider,
    url      => $url
  }

}
