# mongodb puppet module

[![Build Status](https://travis-ci.org/puppetlabs/puppetlabs-mongodb.png?branch=master)](https://travis-ci.org/puppetlabs/puppetlabs-mongodb)

## Overview

Installs mongodb on RHEL/Ubuntu/Debian from OS repo, or alternatively per 10gen [installation documentation](http://www.mongodb.org/display/DOCS/Ubuntu+and+Debian+packages).

## Deprecation Warning ##

Release 0.3 will be the final prototypical release for the puppetlabs-mongodb module. The development api should
be considered deprecated and will not work for the forthcoming 1.0 module release. If your project depends
on the current API, please pin your dependencies to ensure your environments don't break.

## Usage

### class mongodb

Parameters:
* enable_10gen (default: false) - Whether or not to set up 10gen software repositories
* init (auto discovered) - override init (sysv or upstart) for Debian derivatives
* location - override apt location configuration for Debian derivatives
* packagename (auto discovered) - override the package name
* servicename (auto discovered) - override the service name
* service_enable (default: true) - enable or disable the service

By default ubuntu is upstart and debian uses sysv.

Examples:

    class { 'mongodb':
      init => 'sysv',
    }

    class { 'mongodb':
      enable_10gen => true,
    }

## Supported Platforms

* Debian Wheezy
* Ubuntu 12.04 (precise)
* RHEL 6

## Testing

Module testing should be run under Bundler with the gem versions as specified
in the Gemfile. Test setup and teardown is handled with rake tasks, so the
supported way of running tests is with `bundle exec rake spec`.

Installing testing dependencies:

    $ bundle install
    Fetching gem metadata from https://rubygems.org/.........
    Fetching gem metadata from https://rubygems.org/..
    Installing rake (10.1.0) 
    Installing diff-lcs (1.1.3) 
    Installing facter (1.6.18) 
    Installing json_pure (1.8.1) 
    Installing hiera (1.2.1) 
    Installing metaclass (0.0.1) 
    Installing mocha (0.10.5) 
    Installing rgen (0.6.6) 
    Installing puppet (3.3.1) 
    Installing rspec-core (2.10.1) 
    Installing rspec-expectations (2.10.0) 
    Installing rspec-mocks (2.10.1) 
    Installing rspec (2.10.0) 
    Installing rspec-puppet (0.1.6) 
    Installing puppetlabs_spec_helper (0.4.1) 
    Using bundler (1.3.5) 
    Your bundle is complete!

Running the tests:

    $ bundle exec rake spec
    Cloning into 'spec/fixtures/modules/stdlib'...
    remote: Counting objects: 4313, done.
    remote: Compressing objects: 100% (2482/2482), done.
    remote: Total 4313 (delta 1667), reused 3895 (delta 1296)
    Receiving objects: 100% (4313/4313), 748.71 KiB | 409.00 KiB/s, done.
    Resolving deltas: 100% (1667/1667), done.
    Checking connectivity... done
    HEAD is now at d60d872 Merge branch 'pull-180'
    Cloning into 'spec/fixtures/modules/apt'...
    remote: Counting objects: 1361, done.
    remote: Compressing objects: 100% (909/909), done.
    remote: Total 1361 (delta 669), reused 1085 (delta 433)
    Receiving objects: 100% (1361/1361), 239.60 KiB | 392.00 KiB/s, done.
    Resolving deltas: 100% (669/669), done.
    Checking connectivity... done
    HEAD is now at a350da7 Merge pull request #182 from stefanvanwouw/master
    /home/adrien/.rbenv/versions/1.9.3-p392/bin/ruby -S rspec spec/classes/mongodb_spec.rb --color
    ..........
    Finished in 1.54 seconds
    10 examples, 0 failures
