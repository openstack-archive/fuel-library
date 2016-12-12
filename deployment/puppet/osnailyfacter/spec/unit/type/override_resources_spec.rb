require 'puppet'
require_relative '../../../lib/puppet/type/override_resources'
require 'yaml'

describe Puppet::Type.type(:override_resources) do

  let(:facts) do
    {
      :osfamily        => 'Debian',
      :operatingsystem => 'Debian',
    }
 end

  let(:catalog) do
    Puppet::Resource::Catalog.new()
  end

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
file:
  '/tmp/test':
    content: "123"
  '/etc/httpd/httpd.conf':
    source: 'puppet:///modules/httpd/httpd.conf'
    owner: httpd
    group: httpd
    notify: 'Service[httpd]'
service:
  httpd:
    ensure: running
    enable: true
  nginx:
    ensure: stopped
    enable: false
package:
  htop:
    ensure: absent
  ntpd:
    ensure: present
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

  let(:conf_with_cycle) do
    YAML.load <<-eof
---
file:
  '/tmp/foo':
    notify: "File[/tmp/bar]"
  '/tmp/bar':
    notify: "File[/tmp/foo]"
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

  it 'should create resource with notify' do
    catalog.clear
    override_resources.catalog = catalog
    override_resources[:create] = true
    override_resources.eval_generate
    opts = {'event' => :ALL_EVENTS, 'callback' => :refresh}
    source_resource = catalog.resource 'file', '/etc/httpd/httpd.conf'
    target_resource = catalog.resource 'service', 'httpd'
    relationship = Puppet::Relationship.new(source_resource, target_resource, options=opts)

    expect(
      catalog.relationship_graph.edges.map {|e| e.to_json}.include? relationship.to_json
    ).to eq(true)
  end

  it 'should raise for config with cycles' do
    catalog.clear
    override_resources.catalog = catalog
    override_resources[:create] = true
    override_resources[:configuration] = conf_with_cycle
    expect {
      override_resources.eval_generate
    }.to raise_error(Puppet::Error, /dependency cycle/)
  end
end
