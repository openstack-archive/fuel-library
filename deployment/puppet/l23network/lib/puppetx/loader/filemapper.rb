require_relative 'loader'

PuppetLoader.load(
    'puppetx/filemapper',
    './../../../../filemapper/lib/puppetx/filemapper',
    './../../../spec/fixtures/modules/filemapper/lib/puppetx/filemapper',
    '/var/lib/puppet/lib/puppetx/filemapper',
    '/etc/puppet/modules/filemapper/lib/puppetx/filemapper',
)
