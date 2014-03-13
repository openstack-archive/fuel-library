require 'spec_helper'

describe 'logstash::input::stdin', :type => 'define' do

  let(:facts) { {:operatingsystem => 'CentOS' }}
  let(:pre_condition) { 'class {"logstash": }'}
  let(:title) { 'test' }

  context "Input test" do

    let :params do {
      :add_field => { 'field1' => 'value1' },
      :charset => 'ASCII-8BIT',
      :debug => false,
      :format => 'plain',
      :message_format => 'value5',
      :tags => ['value6'],
      :type => 'value7',
    } end

    it { should contain_file('/etc/logstash/agent/config/input_stdin_test').with(:content => "input {\n stdin {\n  add_field => [\"field1\", \"value1\"]\n  charset => \"ASCII-8BIT\"\n  debug => false\n  format => \"plain\"\n  message_format => \"value5\"\n  tags => ['value6']\n  type => \"value7\"\n }\n}\n") }
  end

  context "Instance test" do

    let :params do {
      :add_field => { 'field1' => 'value1' },
      :charset => 'ASCII-8BIT',
      :debug => false,
      :format => 'plain',
      :message_format => 'value5',
      :tags => ['value6'],
      :type => 'value7',
      :instances => [ 'agent1', 'agent2' ]
    } end
  
    it { should contain_file('/etc/logstash/agent1/config/input_stdin_test') }
    it { should contain_file('/etc/logstash/agent2/config/input_stdin_test') }

  end

  context "Set file owner" do

    let(:facts) { {:operatingsystem => 'CentOS' }}
    let(:pre_condition) { 'class {"logstash": logstash_user => "logstash", logstash_group => "logstash" }'}
    let(:title) { 'test' }

    let :params do {
      :add_field => { 'field1' => 'value1' },
      :charset => 'ASCII-8BIT',
      :debug => false,
      :format => 'plain',
      :message_format => 'value5',
      :tags => ['value6'],
      :type => 'value7',
    } end
  
    it { should contain_file('/etc/logstash/agent/config/input_stdin_test').with(:owner => 'logstash', :group => 'logstash') }

  end

end
