require 'puppet'
require 'puppet/type/zabbix_template_link'


describe 'Puppet::Type.type(:zabbix_template_link)' do

  before :each do
    @type_instance = Puppet::Type.type(:zabbix_template_link).new(:name => 'testimport')
  end

  it 'should accept non-empty name' do
    @type_instance[:name] = 'New link'
    @type_instance[:name] == 'New link'
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

  it 'should accept non-empty template name' do
    @type_instance[:template] = 'template'
    @type_instance[:template] == 'template'
  end

  it 'should not accept empty template name' do
    expect {
      @type_instance[:template] = ''
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
