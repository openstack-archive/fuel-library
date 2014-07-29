# SSL Management Module #

This module provides a standard way to manage your SSL certificates, and
currently includes support for auto-downloading your signed certs from
InCommon.

Supported platforms are RedHat, Debian and Archlinux (based on $::osfamily
fact).  Pull requests for other platforms are welcomed.

## Dependencies ##

* puppetlabs-stdlib >= 2.6.0 (may work with earlier versions)

# Usage #

As it stands, the intention is for the ssl::cert defined type to be used to
build a self-signed cert.  This process also generates a CSR for us.  This is
what needs to be submitted to the signing authority.

Once the signing authority signs your cert request, you can plug in the
relevant
certificate id into the appropriate ssl defined type, and it will automatically
download and install the cert for you.

Currently, the only supported signing authority is InCommon (ssl::incommon),
but this can easily be expanded to others.

## Example ##

<pre><code>
  include ssl
  
  ssl::cert { 'www.example.com':
    alt_names => [ 'www2.example.com' ],
    country   => 'US',
    org       => 'Example.com, LLC',
    org_unit  => 'Web Team',
    state     => 'CA',
  }

  # once we receive our email confirmation with out cert#, we can enter it into
  # the id field, and it will automatically be downloaded if necessary.
  ssl::incommon { 'www.example.com': id => '12345' }
</code></pre>

License
-------

See LICENSE file

Copyright
---------

Copyright &copy; 2013 The Regents of the University of California

Contributors:
-------------

**Eric Rasche**

  * Debian/Ubuntu Support

**Niels Abspoel**

  * Archlinux Support

Contact
-------

Aaron Russo <arusso@berkeley.edu>

Support
-------

Please log tickets and issues at the
[Projects site](https://github.com/arusso/puppet-ssl/issues/)
