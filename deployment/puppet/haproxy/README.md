# haproxy

This haproxy uses storeconfigs to collect and realize balancer member servers
on a load balancer server.  Currently Redhat family OSes are supported, but
support for other OS Families shouldn't be too difficult to merge in.  Pull
requests accepted!

## Hacking

After cloning the repository, execute `git submodule update --init` to pull in
any dependencies needed to test the module locally.

1. `git submodule update --init`
1. `rake spec` # To run the tests
1. Hack Hack Hack # Adding tests hopefully!
1. Commit and send a pull request!

## License

Apache 2.0

## Contact

Gary Larizza <gary@puppetlabs.com>
