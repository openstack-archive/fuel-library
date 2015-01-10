# puppet-rsyslog [![Build Status](https://secure.travis-ci.org/saz/puppet-rsyslog.png)](https://travis-ci.org/saz/puppet-rsyslog)

Manage rsyslog client and server via Puppet

## REQUIREMENTS

* Puppet >=2.6 if using parameterized classes
* Currently supports Ubuntu >=11.04 & Debian running rsyslog >=4.5

## USAGE

### Client

#### Using default values
```
    class { 'rsyslog::client': }
```

#### Variables and default values
```
    class { 'rsyslog::client':
        log_remote            => true,
        spool_size            => '1g',
        remote_type           => 'tcp',
        remote_forward_format => 'RSYSLOG_ForwardFormat',
        log_local             => false,
        log_auth_local        => false,
        custom_config         => undef,
        custom_params         => undef,
        server                => 'log',
        port                  => '514',
        remote_servers        => false,
        ssl_ca                => undef,
        log_templates         => false,
        actionfiletemplate    => false
    }
```
for read from file
```
 rsyslog::imfile { 'my-imfile':
   file_name => '/some/file',
   file_tag => 'mytag',
   file_facility => 'myfacility',
  }

```

#### Defining custom logging templates

The `log_templates` parameter can be used to set up custom logging templates, which can be used for local and/or remote logging. More detail on template formats can be found in the [rsyslog documentation](http://www.rsyslog.com/doc/rsyslog_conf_templates.html).

The following examples sets up a custom logging template as per [RFC3164fmt](https://www.ietf.org/rfc/rfc3164.txt):

```puppet
class{'rsyslog::client':
  log_templates => [
    {
      name      => 'RFC3164fmt',
      template  => '<%PRI%>%TIMESTAMP% %HOSTNAME% %syslogtag%%msg%',
    },
  ]
}
```

#### Logging to multiple remote servers

The `remote_servers` parameter can be used to set up logging to multiple remote servers which are supplied as a list of key value pairs for each remote. There is an example configuration provided in `./test/multiple_hosts.pp`

Using the `remote_servers` parameter over-rides the other remote sever parameters, and they will not be used in the client configuration file:
* `log_remote`
* `remote_type`
* `server`
* `port`

The following example sets up three remote logging hosts for the client:

```puppet
class{'rsyslog::client':
  remote_servers => [
    {
      host => 'logs.example.org',
    },
    {
      port => '55514',
    },
    {
      host      => 'logs.somewhere.com',
      port      => '555',
      pattern   => '*.log',
      protocol  => 'tcp',
      format    => 'RFC3164fmt',
    },
  ]
}
```

Each host has the following parameters:
* *host*: Sets the address or hostname of the remote logging server. Defaults to `localhost`
* *port*: Sets the port the host is listening on. Defaults to `514`
* *pattern*: Sets the pattern to match logs. Defaults to `*.*`
* *protocol*: Sets the protocol. Only recognises TCP and UDP. Defaults to UDP
* *format*: Sets the log format. Defaults to not specifying log format, which defaults to the format set by `ActionFileDefaultTemplate` in the client configuration.

#### Logging to a MySQL or PostgreSQL database

Events can also be logged to a MySQL or PostgreSQL database. The database needs to be deployed separately, either locally or remotely. Schema are available from the `rsyslog` source:

  * [MySQL schema](http://git.adiscon.com/?p=rsyslog.git;a=blob_plain;f=plugins/ommysql/createDB.sql)
  * [PostgreSQL schema](http://git.adiscon.com/?p=rsyslog.git;a=blob_plain;f=plugins/ompgsql/createDB.sql)

Declare the following to configure the connection:
````
    class { 'rsyslog::database':
        backend  => 'mysql',
        server   => 'localhost',
        database => 'Syslog',
        username => 'rsyslog',
        password => 'secret',
    }
````
### Server

#### Using default values
```
    class { 'rsyslog::server': }
```

#### Variables and default values
```
    class { 'rsyslog::server':
        enable_tcp                => true,
        enable_udp                => true,
        enable_onefile            => false,
        server_dir                => '/srv/log/',
        custom_config             => undef,
        high_precision_timestamps => false,
    }
```

Both can be installed at the same time.

## PARAMETERS

The following lists all the class parameters this module accepts.

    RSYSLOG::SERVER CLASS PARAMETERS    VALUES              DESCRIPTION
    -------------------------------------------------------------------
    enable_tcp                          true,false          Enable TCP listener. Defaults to true.
    enable_udp                          true,false          Enable UDP listener. Defaults to true.
    enable_onefile                      true,false          Only one logfile per remote host. Defaults to false.
    server_dir                          STRING              Folder where logs will be stored on the server. Defaults to '/srv/log/'
    custom_config                       STRING              Specify your own template to use for server config. Defaults to undef. Example usage: custom_config => 'rsyslog/my_config.erb'
    high_precision_timestamps           true,false          Whether or not to use high precision timestamps.
    remote_servers                      HASH                Provides a hash of multiple remote logging servers. Check documentation.

    RSYSLOG::CLIENT CLASS PARAMETERS    VALUES              DESCRIPTION
    -------------------------------------------------------------------
    log_remote                          true,false          Log Remotely. Defaults to true.
    spool_size                          STRING              Max size for disk queue if remote server failed. Defaults to '1g'.
    remote_type                         'tcp','udp'         Which protocol to use when logging remotely. Defaults to 'tcp'.
    remote_forward_format               STRING              Which forward format for remote servers should be used. Only used if remote_servers is false.
    log_local                           true,false          Log locally. Defaults to false.
    log_auth_local                      true,false          Just log auth facility locally. Defaults to false.
    custom_config                       STRING              Specify your own template to use for client config. Defaults to undef. Example usage: custom_config => 'rsyslog/my_config.erb'
    custom_params                       TODO                TODO
    server                              STRING              Rsyslog server to log to. Will be used in the client configuration file. Only used, if remote_servers is false.
    port                                '514'               Remote server port. Only used if remote_servers is false.
    remote_servers                      Array of hashes     Array of hashes with remote servers. See documentation above. Defaults to false.
    ssl_ca                              STRING              SSL CA file location. Defaults to undef.
    log_templates                       HASH                Provides a has defining custom logging templates using the `$template` configuration parameter.
    actionfiletemplate                  STRING              If set this defines the `ActionFileDefaultTemplate` which sets the default logging format for remote and local logging.

    RSYSLOG::DATABASE CLASS PARAMETERS  VALUES              DESCRIPTION
    -------------------------------------------------------------------
    backend                             'mysql','pgsql'     Database backend (MySQL or PostgreSQL).
    server                              STRING              Database server.
    database                            STRING              Database name.
    username                            STRING              Database username.
    password                            STRING              Database password.

### Other notes

Due to a missing feature in current RELP versions (InputRELPServerBindRuleset option),
remote logging is using TCP. You can switch between TCP and UDP. As soon as there is
a new RELP version which supports setting Rulesets, I will add support for relp back.

By default, rsyslog::server will strip numbers from hostnames. This means the logs of
multiple servers with the same non-numerical name will be aggregrated in a single
directory. i.e. www01 www02 and www02 would all log to the www directory.

To log each host to a seperate directory, set the custom_config parameter to
'rsyslog/server-hostname.conf.erb'

If any of the following parameters are set to `false`, then the module will not
manage the respective package:

    gnutls_package_name
    relp_package_name
    rsyslog_package_name

This can be used when using the adiscon PPA repository, that has merged rsyslog-gnutls
with the main rsyslog package.
