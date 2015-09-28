# fuel-library
--------------

## Table of Contents

1. [Overview - What is the fuel-library?](#overview)
2. [Structure - What is in the fuel-library?](#structure)
3. [Granular Deployment - What is the granular deployment for Fuel?](#granular-deployment)
4. [Upstream Modules - How to work with librarian.](#upstream-modules)
5. [Testing - How to run fuel-library tests.](#testing)
6. [Development](#development)
7. [Core Reviers](#core-reviewers)
8. [Contributors](#contributors)

## Overview
-----------

The fuel-library is collection of Puppet modules and related code used by Fuel to deploy OpenStack environments.


## Structure
------------

### Basic Repository Layout

```
fuel-library
├── CHANGELOG
├── LICENSE
├── README.md
├── debian
├── deployment
├── files
├── specs
├── tests
└── utils
```

### root

The root level contains important repository documentation and license information.

### debian/

This folder contains the required information to create fuel-library debian packages.

### deployment/

This folder contains the fuel-library Puppet code, the Puppetfile for upstream modules, and scripts to manage modules with [librarian-puppet-simple](https://github.com/bodepd/librarian-puppet-simple).

### files/

This folder contains scripts and configuration files that are used when creating the packages for fuel-library.

### specs/

This folder contains our rpm spec file for fuel-library rpm packages.

### tests/

This folder contains our testing scripts for the fuel-library.

### utils/

This folder contains scripts that are useful when doing development on fuel-library

## Granular Deployment
----------------------

TODO.

## Upstream Modules
-------------------

In order to be able to pull in upstream modules for use by the fuel-library, the deployment folder contains a Puppetfile for use with [librarian-puppet-simple](https://github.com/bodepd/librarian-puppet-simple). Upstream modules should be used whenever possible. For additional details on the process for working with upstream modules, please read the [Fuel library for Puppet manifests](https://wiki.openstack.org/wiki/Fuel/How_to_contribute#Fuel_library_for_puppet_manifests) of the [Fuel wiki](https://wiki.openstack.org/wiki/Fuel).

## Testing
----------

Testing is important for the fuel-library to ensure changes do what they are supposed to do, regressions are not introduced and all code is of the highest quality. The fuel-library leverages existing Puppet module rspec tests, [bats](https://github.com/sstephenson/bats) tests for bash scripts and noop tests for testing the module deployment tasks in fuel-library.

### Puppet module tests

TODO.

### Bats: Bash Automated Testing System

TODO.

### fuel-library noop

TODO.

## Development
--------------

* [Fuel Development Documentation](https://docs.fuel-infra.org/fuel-dev/)
* [Fuel How to Contribute](https://wiki.openstack.org/wiki/Fuel/How_to_contribute)

## Core Reviewers
-----------------

* [Fuel Cores](https://review.openstack.org/#/admin/groups/209,members)
* [Fuel Library Cores](https://review.openstack.org/#/admin/groups/658,members)

## Contributors
---------------

* [Stackalytics](http://stackalytics.com/?release=all&project_type=all&module=fuel-library&metric=commits)
