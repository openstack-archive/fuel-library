require_relative 'loader'

PuppetLoader.load(
    # the right way, load using "puppetx" path
    'puppetx/l23network',
    # load relatively through the puppet modules
    './../../../l23network/lib/puppetx/l23network',
    # load relatively from the modules in the fixtures
    '../../spec/fixtures/modules/l23network/lib/puppetx/l23network',
    # load from the "var" directory after plugin sync
    '/var/lib/puppet/lib/puppetx/l23network',
    # the last resort, load by the absolute path
    '/etc/puppet/modules/l23network/lib/puppetx/l23network',
)
