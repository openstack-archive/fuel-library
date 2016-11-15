require 'puppet'
require_relative '../../../lib/puppet/type/override_resources'
require 'yaml'

describe Puppet::Type.type(:override_resources) do

  let(:override_resources) do
    Puppet::Type.type(:override_resources).new(
        :name => 'foo',
        :configuration => configuration,
        :options => options,
    )
  end

  subject { override_resources }

  let(:configuration) do
    YAML.load <<-eof
---
nova_config:
  DEFAULT/debug:
    value: true
  DEFAULT/verbose:
    ensure: absent
file:
  '/tmp/test':
    content: 123
  '/etc/httpd/httpd.conf':
    source: 'puppet:///modules/httpd/httpd.conf'
    owner: httpd
    group: httpd
    notify: 'Service[httpd]'
  my_symlink:
    ensure: symlink
    path: '/tmp/test1'
    target: '/tmp/test'
service:
  httpd:
    ensure: running
    enable: true
  nginx:
    ensure: stopped
    enable: false
package:
  mc:
  htop:
    ensure: absent
  ntpd:
    ensure: latest
  my_package:
    ensure: 1
    eof
  end

  let(:options) do
    YAML.load <<-eof
---
types_filter: []
titles_filter: []
create: false
types_create_exception: []
titles_create_exception: []
defaults:
  package:
    ensure: present
  file:
    ensure: present
    eof
  end

  it 'should require a name' do
    expect {
      Puppet::Type.type(:override_resources).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'should require configuration to be a hash' do
    expect {
      override_resources[:configuration] = 'string => data'
      override_resources.eval_generate
    }.to raise_error(Puppet::ResourceError, /Configuration data should contain a resources hash!/)
  end

  it 'should contain resource defaults hash' do
    expect {
      override_resources[:defaults] = 'string => data'
      override_resources.eval_generate
    }.to raise_error(Puppet::ResourceError, /Defaults data should contain a defaults hash!/)
  end

  it 'should accept a resource type into types_filter' do
    type = 'keystone_config'
    override_resources[:types_filter] = type
    expect(override_resources[:types_filter]).to eq(type)
  end

  it 'should accept a resource type into types_create_exception' do
    type = 'keystone_config'
    override_resources[:types_create_exception] = type
    expect(override_resources[:types_create_exception]).to eq(type)
  end

  it 'should accept a resource type into titles_filter' do
    title = 'bar'
    override_resources[:titles_filter] = title
    expect(override_resources[:titles_filter]).to eq(title)
  end

  it 'should accept a resource title into titles_create_exception' do
    title = 'bar'
    override_resources[:titles_create_exception] = title
    expect(override_resources[:titles_create_exception]).to eq(title)
  end

  it 'should accept defaults data' do
    data = {
      'DEFAULT/debug' => { 'value' => false },
      'DEFAULT/max_param_size' => { 'value' => 128 }
    }
    override_resources[:defaults] = data
    expect(override_resources[:defaults]).to eq(data)
  end

  it 'should accept create flag' do
    cr = true
    override_resources[:create] = cr
    expect(override_resources[:create]).to eq(cr)
  end
end
