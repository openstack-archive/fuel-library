# Class for creating floating ip range
# - ip_range = ['192.168.1.1-192.168.1.55','192.168.2.1-192.168.2.66']
class nova::manage::floating_range (
  $ip_range,
  $pool     = 'nova',
  $username = 'admin',
  $api_key  = 'nova',
  $password = 'nova',
  $auth_url =  undef,
  $authtenant_name = 'admin',
){
  nova_floating_range{$ip_range:
    ensure          => 'present',
    pool            => $pool,
    username        => $username,
    api_key         => $api_key,
    auth_method     => $password,
    auth_url        => $auth_url,
    authtenant_name => $authtenant_name,
  }
}