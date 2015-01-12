# xinetd
[![Build Status](https://travis-ci.org/puppetlabs/puppetlabs-xinetd.png)](https://travis-ci.org/puppetlabs/puppetlabs-xinetd)

This is the xinetd module.

## Overview

This module configures xinetd, and exposes the xinetd::service definition
for adding new services.

## Class: xinetd

Sets up the xinetd daemon. Has options for you in case you have specific
package names and service needs.

### Parameters

 * `confdir`
 * `conffile`
 * `package_name`
 * `service_name`
 * `service_restart`
 * `service_status`
 * `service_hasrestart`
 * `service_hasstatus`

## Definition: xinetd::service

Sets up a xinetd service. All parameters match up with xinetd.conf(5) man
page.

### Parameters:

 * `server`       - required - determines the program to execute for this service
 * `port`         - required - determines the service port
 * `cps`          - optional
 * `flags`        - optional
 * `per_source`   - optional
 * `server_args`  - optional
 * `disable`      - optional - defaults to "no"
 * `socket_type`  - optional - defaults to "stream"
 * `protocol`     - optional - defaults to "tcp"
 * `user`         - optional - defaults to "root"
 * `group`        - optional - defaults to "root"
 * `instances`    - optional - defaults to "UNLIMITED"
 * `wait`         - optional - based on $protocol will default to "yes" for udp and "no" for tcp
 * `service_type` - optional - type setting in xinetd

### Sample Usage

```puppet
xinetd::service { 'tftp':
  port        => '69',
  server      => '/usr/sbin/in.tftpd',
  server_args => '-s /var/lib/tftp/',
  socket_type => 'dgram',
  protocol    => 'udp',
  cps         => '100 2',
  flags       => 'IPv4',
  per_source  => '11',
}
```

## Supported OSes

Supports Debian, FreeBSD, Suse, RedHat, and Amazon Linux OS Families. 



