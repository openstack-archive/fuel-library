Requirements
============

[![Build Status](https://travis-ci.org/duritong/puppet-sysctl.png?branch=master)](https://travis-ci.org/duritong/puppet-sysctl)

Overview
--------

This modules allows to configure sysctl.

Usage
-----

    node "mynode" inherits ... {
      sysctl::value { "vm.nr_hugepages": value => "1583"}
    }

When setting a key that contains multiple values, use a tab to separate the
values:

    node "mynode" inherits ... {
      sysctl::value { 'net.ipv4.tcp_rmem':
          value => "4096\t131072\t131072",
      }
    }

To avoid duplication the sysctl::value calls multiple settings can be
managed like this:

    $my_sysctl_settings = {
      "net.ipv4.ip_forward"          => { value => 1 },
      "net.ipv6.conf.all.forwarding" => { value => 1 },
    }
    
    # Specify defaults for all the sysctl::value to be created (
    $my_sysctl_defaults = {
      require => Package['aa']
    }
    
    create_resources(sysctl::value,$my_sysctl_settings,$my_sysctl_defaults)

The sysctl binary needs to be found in your Path.
It is preferred that you set your exec path globally. This is usually done
in site.pp and would look something like this (adjust for your environment):

    # Set a site-wide global path so we don't have to explicitly specify a path
    # for each exec.
    Exec { path => '/usr/bin:/usr/sbin:/bin:/sbin' }

Or you can also set that path within hiera for `sysctl::params::exec_path`.

License
-------

Copyright (C) 2011 Immerda Project Group
Author mh <mh@immerda.ch>
Modified by Nicolas Zin <nicolas.zin@savoirfairelinux.com>
Licence: GPL v2
