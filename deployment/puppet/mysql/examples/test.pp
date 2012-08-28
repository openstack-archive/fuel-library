# Class: mysql::config
#
# Parameters:
#
#   [*root_password*]     - root user password.
#   [*old_root_password*] - previous root user password,
#   [*bind_address*]      - address to bind service.
#   [*port*]              - port to bind service.
#   [*etc_root_password*] - whether to save /etc/.my.cnf.
#   [*service_name*]      - mysql service name.
#   [*config_file*]       - my.cnf configuration file path.
#   [*socket*]            - mysql socket.
#   [*datadir*]           - path to datadir.
#   [*ssl]                - enable ssl
#   [*ssl_ca]             - path to ssl-ca
#   [*ssl_cert]           - path to ssl-cert
#   [*ssl_key]            - path to ssl-key
#
class {'mysql::server':
  config_hash =>{
    'root_password' => 'r00tme',
    'bind_address'  => '0.0.0.0'
  },
}

