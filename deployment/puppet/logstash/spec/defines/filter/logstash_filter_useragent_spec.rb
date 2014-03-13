require 'spec_helper'

describe 'logstash::filter::useragent', :type => 'define' do

  let(:facts) { {:operatingsystem => 'CentOS' }}
  let(:pre_condition) { 'class {"logstash": }'}
  let(:title) { 'test' }

  context "Input test" do

    let :params do {
      :add_field => { 'field1' => 'value1' },
      :add_tag => ['value2'],
      :exclude_tags => ['value3'],
      :regexes => 'value4',
      :remove_tag => ['value5'],
      :source => 'value6',
      :tags => ['value7'],
      :target => 'value8',
      :type => 'value9',
    } end

    it { should contain_file('/etc/logstash/agent/config/filter_10_useragent_test').with(:content => "filter {\n useragent {\n  add_field => [\"field1\", \"value1\"]\n  add_tag => ['value2']\n  exclude_tags => ['value3']\n  regexes => \"value4\"\n  remove_tag => ['value5']\n  source => \"value6\"\n  tags => ['value7']\n  target => \"value8\"\n  type => \"value9\"\n }\n}\n") }
  end

  context "Instance test" do

    let :params do {
      :add_field => { 'field1' => 'value1' },
      :add_tag => ['value2'],
      :exclude_tags => ['value3'],
      :regexes => 'value4',
      :remove_tag => ['value5'],
      :source => 'value6',
      :tags => ['value7'],
      :target => 'value8',
      :type => 'value9',
      :instances => [ 'agent1', 'agent2' ]
    } end
  
    it { should contain_file('/etc/logstash/agent1/config/filter_10_useragent_test') }
    it { should contain_file('/etc/logstash/agent2/config/filter_10_useragent_test') }

  end

  context "Set file owner" do

    let(:facts) { {:operatingsystem => 'CentOS' }}
    let(:pre_condition) { 'class {"logstash": logstash_user => "logstash", logstash_group => "logstash" }'}
    let(:title) { 'test' }

    let :params do {
      :add_field => { 'field1' => 'value1' },
      :add_tag => ['value2'],
      :exclude_tags => ['value3'],
      :regexes => 'value4',
      :remove_tag => ['value5'],
      :source => 'value6',
      :tags => ['value7'],
      :target => 'value8',
      :type => 'value9',
    } end
  
    it { should contain_file('/etc/logstash/agent/config/filter_10_useragent_test').with(:owner => 'logstash', :group => 'logstash') }

  end

end
