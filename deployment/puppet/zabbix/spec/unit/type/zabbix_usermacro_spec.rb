require 'puppet'
require 'puppet/type/zabbix_usermacro'


describe 'Puppet::Type.type(:zabbix_usermacro)' do

  before :each do
    @type_instance = Puppet::Type.type(:zabbix_usermacro).new(:name => 'testimport', :host => "host")
  end

  it 'should fail with global = true and specified host' do
    expect {
      Puppet::Type.type(:zabbix_usermacro).new(:name => "new", :global => :true, :host => "host")
    }.to raise_error(Puppet::Error, /should not be provided/)
  end

  it 'should fail with global = false and unspecified host' do
    expect {
      Puppet::Type.type(:zabbix_usermacro).new(:name => "new")
    }.to raise_error(Puppet::Error, /host is required/)
  end

  it 'should accept non-empty name' do
    @type_instance[:name] = 'New macro'
    @type_instance[:name] == 'New macro'
  end

  it 'should not accept empty name' do
    expect {
      @type_instance[:name] = ''
    }.to raise_error(Puppet::Error, /Parameter.+failed/)
  end

  it 'should accept non-empty host' do
    @type_instance[:host] = 'node-1'
    @type_instance[:host] == 'node-1'
  end

  it 'should not accept empty host' do
    expect {
      @type_instance[:host] = ''
    }.to raise_error(Puppet::Error, /Parameter.+failed/)
  end

  it 'should accept non-empty macro name' do
    @type_instance[:macro] = 'macro'
    @type_instance[:macro] == 'macro'
  end

  it 'should not accept empty macro name' do
    expect {
      @type_instance[:macro] = ''
    }.to raise_error(Puppet::Error, /Parameter.+failed/)
  end

  it 'should accept non-empty macro value' do
    @type_instance[:value] = 'value'
    @type_instance[:value] == 'value'
  end

  it 'should not accept empty macro value' do
    expect {
      @type_instance[:value] = ''
    }.to raise_error(Puppet::Error, /Parameter.+failed/)
  end

  it 'should accept valid api hash' do
    @type_instance[:api] = {"username" => "user",
                          "password" => "password",
                          "endpoint" => "http://endpoint"}
  end

  it 'should not accept non-hash objects for api hash' do
    expect {
      @type_instance[:api] = "qwerty"
    }.to raise_error(Puppet::Error, /Parameter.+failed/)
  end

  it 'should not accept api hash without any of required keys' do
    expect {
      @type_instance[:api] = {"password" => "password",
                            "endpoint" => "http://endpoint"}
    }.to raise_error(Puppet::Error, /Parameter.+failed/)

    expect {
      @type_instance[:api] = {"username" => "username",
                            "endpoint" => "http://endpoint"}
    }.to raise_error(Puppet::Error, /Parameter.+failed/)

    expect {
      @type_instance[:api] = {"username" => "username",
                            "password" => "password"}
    }.to raise_error(Puppet::Error, /Parameter.+failed/)
  end

  it 'should not accept api hash with invalid keys' do
    expect {
      @type_instance[:api] = {"username" => [],
                            "password" => "password",
                            "endpoint" => "http://endpoint"}
    }.to raise_error(Puppet::Error, /Parameter.+failed/)

    expect {
      @type_instance[:api] = {"username" => "username",
                            "password" => [],
                            "endpoint" => "http://endpoint"}
    }.to raise_error(Puppet::Error, /Parameter.+failed/)

    expect {
      @type_instance[:api] = {"username" => "username",
                            "password" => "password",
                            "endpoint" => "endpoint"}
    }.to raise_error(Puppet::Error, /Parameter.+failed/)

    expect {
      @type_instance[:api] = {"username" => "username",
                            "password" => "password",
                            "endpoint" => []}
    }.to raise_error(Puppet::Error, /Parameter.+failed/)
  end

end
