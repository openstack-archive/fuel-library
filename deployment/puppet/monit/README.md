# Monit Module

[![Build Status](https://travis-ci.org/jbussdieker/puppet-monit.png?branch=master)](https://travis-ci.org/jbussdieker/puppet-monit)

This module manages installing, configuring and running processes using monit.

http://forge.puppetlabs.com/jbussdieker/monit

## Parameters

 * ensure: running, stopped. default: running
 * start_command: Command line to start service.
 * stop_command: Command line to stop service.
 * pidfile: Location to find the pid file.

## Usage

    monit::process {'myapp':
      ensure        => running,
      start_command => '/etc/init.d/myapp start',
      stop_command  => '/etc/init.d/myapp stop',
      pidfile       => '/var/run/myapp/myapp.pid',
    }
