require 'puppet'
require 'puppet/type/zabbix_host'


describe 'Puppet::Type.type(:zabbix_host)' do

  before :each do
    @zabbix_host = Puppet::Type.type(:zabbix_host).new(:name => 'testhost', :host => 'testhost', :groups => ['testgroup'])
  end

  it 'should accept valid IP address' do
    @zabbix_host[:ip] = '192.168.10.1'
    @zabbix_host[:ip] == '192.168.10.1'
  end

  it 'should not accept IP address with more than 3 digits per octet' do
    expect {
      @zabbix_host[:ip] = '1921.168.10.1'
    }.to raise_error(Puppet::Error, /Invalid value/)
  end

  it 'should not accept random strings for IP address' do
    expect {
      @zabbix_host[:ip] = 'hello'
    }.to raise_error(Puppet::Error, /Invalid value/)
  end

  it 'should accept valid namevar' do
    @zabbix_host[:host] = 'host name'
    @zabbix_host[:ip] == 'host name'
  end

  it 'should not accept empty namevar' do
    expect {
      @zabbix_host[:host] = ''
    }.to raise_error(Puppet::Error, /Invalid value/)
  end

  it 'should accept valid group list' do
    @zabbix_host[:groups] = ['ManagedByPuppet', 'OpenStack9000']
  end

  it 'should accept string for group list' do
    @zabbix_host[:groups] = 'ManagedByPuppet'
  end

  it 'should not accept non-array non-string object for groups list' do
    expect {
      @zabbix_host[:groups] = 123
    }.to raise_error(Puppet::Error, /Parameter.+failed/)
  end

  it 'should not accept empty array for groups' do
    expect {
      @zabbix_host[:groups] = []
    }.to raise_error(Puppet::Error, /Parameter.+failed/)
  end

  it 'should not accept array with non-string items for groups' do
    expect {
      @zabbix_host[:groups] = ['hello', 123, nil]
    }.to raise_error(Puppet::Error, /Parameter.+failed/)
  end

  it 'should not accept array with empty strings for groups' do
    expect {
      @zabbix_host[:groups] = ['hello', ""]
    }.to raise_error(Puppet::Error, /Parameter.+failed/)
  end

  it 'should accept valid hostname' do
    @zabbix_host[:hostname] = 'node-1'
    @zabbix_host[:hostname] == 'node-1'
  end

  it 'should not accept non-string hostname' do
    expect {
      @zabbix_host[:hostname] = []
    }.to raise_error(Puppet::Error, /Invalid value/)
  end

  it 'should accept valid proxy_id' do
    @zabbix_host[:proxy_hostid] = '1'
    @zabbix_host[:proxy_hostid] == '1'
    @zabbix_host[:proxy_hostid] = 1
    @zabbix_host[:proxy_hostid] == 1
  end

  it 'should not accept invalid proxyid' do
    expect {
      @zabbix_host[:proxy_hostid] = []
    }.to raise_error(Puppet::Error, /Parameter.+failed/)

    expect {
      @zabbix_host[:proxy_hostid] = "qwerty"
    }.to raise_error(Puppet::Error, /Parameter.+failed/)
  end

  it 'should accept valid status' do
    @zabbix_host[:status] = 1
    @zabbix_host[:status] == 1
    @zabbix_host[:status] = 0
    @zabbix_host[:status] == 0
  end

  it 'should not accept invalid proxyid' do
    expect {
      @zabbix_host[:status] = "qwerty"
    }.to raise_error(Puppet::Error, /Invalid value/)
  end

  it 'should accept valid api hash' do
    @zabbix_host[:api] = {"username" => "user",
                          "password" => "password",
                          "endpoint" => "http://endpoint"}
  end

  it 'should not accept non-hash objects for api hash' do
    expect {
      @zabbix_host[:api] = "qwerty"
    }.to raise_error(Puppet::Error, /Parameter.+failed/)
  end

  it 'should not accept api hash without any of required keys' do
    expect {
      @zabbix_host[:api] = {"password" => "password",
                            "endpoint" => "http://endpoint"}
    }.to raise_error(Puppet::Error, /Parameter.+failed/)

    expect {
      @zabbix_host[:api] = {"username" => "username",
                            "endpoint" => "http://endpoint"}
    }.to raise_error(Puppet::Error, /Parameter.+failed/)

    expect {
      @zabbix_host[:api] = {"username" => "username",
                            "password" => "password"}
    }.to raise_error(Puppet::Error, /Parameter.+failed/)
  end

  it 'should not accept api hash with invalid keys' do
    expect {
      @zabbix_host[:api] = {"username" => [],
                            "password" => "password",
                            "endpoint" => "http://endpoint"}
    }.to raise_error(Puppet::Error, /Parameter.+failed/)

    expect {
      @zabbix_host[:api] = {"username" => "username",
                            "password" => [],
                            "endpoint" => "http://endpoint"}
    }.to raise_error(Puppet::Error, /Parameter.+failed/)

    expect {
      @zabbix_host[:api] = {"username" => "username",
                            "password" => "password",
                            "endpoint" => "endpoint"}
    }.to raise_error(Puppet::Error, /Parameter.+failed/)

    expect {
      @zabbix_host[:api] = {"username" => "username",
                            "password" => "password",
                            "endpoint" => []}
    }.to raise_error(Puppet::Error, /Parameter.+failed/)
  end

end
