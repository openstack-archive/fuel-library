require_relative 'loader'

PuppetLoader.load(
    # the right way, load using the "puppetx" path
    'puppetx/l23network',
    # load relatively from inside the "lib" dir
    './../../puppetx/l23network',
    # load relatively from the "var" directory after plugin sync
    '/var/lib/puppet/lib/puppetx/l23network',
    # the last resort, load by the absolute path
    '/etc/puppet/modules/l23network/lib/puppetx/l23network',
)
