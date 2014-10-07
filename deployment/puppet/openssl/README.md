# OpenSSL Puppet Module

[![Build Status](https://travis-ci.org/camptocamp/puppet-openssl.png?branch=master)](https://travis-ci.org/camptocamp/puppet-openssl)

**This module manages OpenSSL.**

## Types and providers

This module provides three types and associated providers to manage SSL keys and certificates.


### ssl\_pkey

This type allows to generate SSL private keys.

Simple usage:

    ssl_pkey { '/path/to/private.key': }

Advanced options:

    ssl_pkey { '/path/to/private.key':
      ensure   => 'present',
      password => 'j(D$',
    }

### x509\_cert

This type allows to generate SSL certificates from a private key. You need to deploy a `template` file (`templates/cert.cnf.erb` is an example).

Simple usage:

    x509_cert { '/path/to/certificate.crt': }

Advanced options:

    x509_cert { '/path/to/certificate.crt':
      ensure      => 'present',
      password    => 'j(D$',
      template    => '/other/path/to/template.cnf',
      private_key => '/there/is/my/private.key',
      days        => 4536,
      force       => false,
    }

### x509\_request

This type allows to generate SSL certificate signing requests from a private key. You need to deploy a `template` file (`templates/cert.cnf.erb` is an example).

Simple usage:

    x509_request { '/path/to/request.csr': }

Advanced options:

    x509_request { '/path/to/request.csr':
      ensure      => 'present',
      password    => 'j(D$',
      template    => '/other/path/to/template.cnf',
      private_key => '/there/is/my/private.key',
      force       => false,
    }

## Definitions

### openssl::certificate::x509

This definition is a wrapper around the `ssl_pkey`, `x509_cert` and `x509_request` types. It generates a certificate template, then generates the private key, certificate and certificate signing request and sets the owner of the files.

Simple usage:

    openssl::certificate::x509 { 'foo':
      country      => 'CH',
      organization => 'Example.com',
      commonname   => $fqdn,
    }

Advanced options:

    openssl::certificate::x509 { 'foo':
      ensure       => present,
      country      => 'CH',
      organization => 'Example.com',
      commonname   => $fqdn,
      state        => 'Here',
      locality     => 'Myplace',
      unit         => 'MyUnit',
      altnames     => ['a.com', 'b.com', 'c.com'],
      email        => 'contact@foo.com',
      days         => 3456,
      base_dir     => '/var/www/ssl',
      owner        => 'www-data',
      group        => 'www-data',
      password     => 'j(D$',
      force        => false,
      cnf_tpl      => 'my_module/cert.cnf.erb'
    }

### openssl::export::pkcs12

This definition generates a pkcs12 file:

    openssl::export::pkcs12 { 'foo':
      ensure    => 'present',
      basedir   => '/path/to/dir',
      pkey      => '/here/is/my/private.key',
      cert      => '/there/is/the/cert.crt',
      pkey_pass => 'mypassword',
    }

## Contributing

Please report bugs and feature request using [GitHub issue
tracker](https://github.com/camptocamp/puppet-openssl/issues).

For pull requests, it is very much appreciated to check your Puppet manifest
with [puppet-lint](https://github.com/rodjek/puppet-lint) to follow the recommended Puppet style guidelines from the
[Puppet Labs style guide](http://docs.puppetlabs.com/guides/style_guide.html).

## License

Copyright (c) 2013 <mailto:puppet@camptocamp.com> All rights reserved.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.


