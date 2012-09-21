# haproxy

This haproxy uses storeconfigs to collect and realize balancer member servers
on a load balancer server.  Currently Redhat family OSes are supported, but
support for other OS Families shouldn't be too difficult to merge in.  Pull
requests accepted!

Read the documentation in the manifest headers for usage information.

## Hacking

After cloning the repository:

1. `gem install puppetlabs_spec_helper`
1. `rake spec` # To run the tests
1. Hack Hack Hack # Adding tests hopefully!
1. Commit and send a pull request!

## License

Apache 2.0

## Contact

Puppet Labs Modules Team <modules@puppetlabs.com>
