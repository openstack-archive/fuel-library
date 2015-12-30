# fuel-library
--------------

## Table of Contents

1. [Overview - What is the fuel-library?](#overview)
2. [Structure - What is in the fuel-library?](#structure)
3. [Granular Deployment - What is the granular deployment for Fuel?](#granular-deployment)
4. [Upstream Modules - How to work with librarian.](#upstream-modules)
5. [Testing - How to run fuel-library tests.](#testing)
6. [Building docs - How to build docs.](#build-docs)
7. [Development](#development)
8. [Core Reviers](#core-reviewers)
9. [Contributors](#contributors)

## Overview
-----------

The fuel-library is collection of Puppet modules and related code used by Fuel
to deploy OpenStack environments.


## Structure
------------

### Basic Repository Layout

```
fuel-library
├── CHANGELOG
├── LICENSE
├── README.md
├── MAINTAINERS
├── debian
├── deployment
├── doc
├── files
├── specs
├── tests
└── utils
```

### root

The root level contains important repository documentation and license
information.

### MAINTAINERS

This is repository level MAINTAINERS file. One submitting a patch should
contact the apropriate maintainer or invite her or him for the code review.
Note, core reviewers are not the maintainers. Normally, cores do reviews
after maintainers.

### debian/

This folder contains the required information to create fuel-library debian
packages.

### deployment/

This folder contains the fuel-library Puppet code, the Puppetfile for
upstream modules, and scripts to manage modules with
[librarian-puppet-simple](https://github.com/bodepd/librarian-puppet-simple).

### doc/

This folder contains RST docs. Currently there is only docs for Noop testing
framework.

### files/

This folder contains scripts and configuration files that are used when
creating the packages for fuel-library.

### specs/

This folder contains our rpm spec file for fuel-library rpm packages.

### tests/

This folder contains our testing scripts for the fuel-library.

### utils/

This folder contains scripts that are useful when doing development on
fuel-library

## Granular Deployment
----------------------

The [top-scope puppet manifests](deployment/puppet/osnailyfacter/modular)
(sometimes also refered as the composition layer) represent the known
deploy paths (aka supported deployment scenarios) for the
[task-based deployment](https://docs.mirantis.com/openstack/fuel/fuel-6.1/reference-architecture.html#task-based-deployment).

## Upstream Modules
-------------------

In order to be able to pull in upstream modules for use by the fuel-library,
the deployment folder contains a Puppetfile for use with
[librarian-puppet-simple](https://github.com/bodepd/librarian-puppet-simple).
Upstream modules should be used whenever possible. For additional details on
the process for working with upstream modules, please read the
[Fuel library for Puppet manifests](https://wiki.openstack.org/wiki/Fuel/How_to_contribute#Fuel_library_for_puppet_manifests)
of the [Fuel wiki](https://wiki.openstack.org/wiki/Fuel).

## Testing
----------

Testing is important for the fuel-library to ensure changes do what they are
supposed to do, regressions are not introduced and all code is of the highest
quality. The fuel-library leverages existing Puppet module rspec tests,
[bats](https://github.com/sstephenson/bats) tests for bash scripts and noop
tests for testing the module deployment tasks in fuel-library.

## Building docs
----------------

You can use tox to prepare virtual environment and build
all RST based guides:

    tox -e docs

You can also build a specific guide. For example, to build *Noop Tests
How-to Guide*, use the following command:

    tox -e build -- noop-guide

You can find the root of the generated HTML documentation at:

    ./doc/noop-guide/build/html/index.html

You can also run docs tests with `tox`.
If you like to run individual tests, run:

> -   `tox -e checkniceness` - to run the niceness tests
> -   `tox -e checksyntax` - to run syntax checks

tox will use the openstack-doc-tools package for execution of these
tests.

### Puppet module tests

Puppet rspec tests should be provided for an every module's directory included.
All of the discovered tests will be automatically executed by the
`rake spec` command issued from the repository root path.

### Bats: Bash Automated Testing System

Shell scripts residing in the `./files` directories should be
covered by the [BATS](https://github.com/sstephenson/bats) test cases.
These should be put under the `./tests/bats` path as well.
Here is an [example](https://review.openstack.org/198355) bats tests
written for the UMM feature.
See also the [bats how-to](https://blog.engineyard.com/2014/bats-test-command-line-tools).

### fuel-library noop

The Noop testing framework is used for testing of the known deploy paths
with existing modular tasks. For details, see the [README](doc/noop-guide/source/README.rst)

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
