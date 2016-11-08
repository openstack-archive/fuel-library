require 'puppet'
require_relative '../../../lib/puppet/type/override_resources'
require 'yaml'

describe Puppet::Type.type(:override_resources) do

  let(:override_resources) do
    Puppet::Type.type(:override_resources).new(
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
types_create: []
titles_create: []
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
      @overres[:configuration] = 'string => data'
      @overres.eval_generate
    }.to raise_error(Puppet::Error, /Data should contain resource hash!$/)
  end

  it 'should contain resource defaults hash' do
    expect {
      @overres[:defaults] = 'string => data'
      @overres.eval_generate
    }.to raise_error(Puppet::Error, /Defaults should contain resource defaults hash!$/)
  end

  it 'should accept a resource type' do
    type = 'keystone_config'
    @overres[:type] = type
    expect(@overres[:type]).to eq(type)
  end

  it 'should accept an override data' do
    data = {
      'DEFAULT/debug' => { 'value' => false },
      'DEFAULT/max_param_size' => { 'value' => 128 }
    }
    @overres[:data] = data
    expect(@overres[:data]).to eq(data)
  end

  it 'should accept create flag' do
    cr = true
    @overres[:create_res] = cr
    expect(@overres[:create_res]).to eq(cr)
  end
end
