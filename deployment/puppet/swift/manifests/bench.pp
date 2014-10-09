# Configure swift-bench.conf for swift performance bench
class swift::bench (
  $auth_url          = 'http://localhost:8080/auth/v1.0',
  $swift_user        = 'test:tester',
  $swift_key         = 'testing',
  $auth_version      = '1.0',
  $log_level         = 'INFO',
  $test_timeout      = '10',
  $put_concurrency   = '10',
  $get_concurrency   = '10',
  $del_concurrency   = '10',
  $lower_object_size = '10',
  $upper_object_size = '10',
  $object_size       = '1',
  $num_objects       = '1000',
  $num_gets          = '10000',
  $num_containers    = '20',
  $delete            = 'yes',
){

  Package['swift'] -> Swift_bench_config<||>

  swift_bench_config {
    'bench/auth':              value => $auth_url;
    'bench/user':              value => $swift_user;
    'bench/key':               value => $swift_key;
    'bench/auth_version':      value => $auth_version;
    'bench/log-level':         value => $log_level;
    'bench/timeout':           value => $test_timeout;
    'bench/put_concurrency':   value => $put_concurrency;
    'bench/get_concurrency':   value => $get_concurrency;
    'bench/del_concurrency':   value => $del_concurrency;
    'bench/lower_object_size': value => $lower_object_size;
    'bench/upper_object_size': value => $upper_object_size;
    'bench/object_size':       value => $object_size;
    'bench/num_objects':       value => $num_objects;
    'bench/num_gets':          value => $num_gets;
    'bench/num_containers':    value => $num_containers;
    'bench/delete':            value => $delete;
  }
}
