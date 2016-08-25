require_relative 'loader'

PuppetLoader.load(
    # the right way, load using the "puppetx" path
    'puppetx/filemapper',
    # load relatively through the puppet modules
    './../../../../filemapper/lib/puppetx/filemapper',
    # load relatively from the modules in the fixtures
    './../../../spec/fixtures/modules/filemapper/lib/puppetx/filemapper',
    # load from the "var" directory after plugin sync
    '/var/lib/puppet/lib/puppetx/filemapper',
    # the last resort, load by the absolute path
    '/etc/puppet/modules/filemapper/lib/puppetx/filemapper',
)
