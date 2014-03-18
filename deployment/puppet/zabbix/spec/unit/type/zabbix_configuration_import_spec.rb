require 'puppet'
require 'puppet/type/zabbix_configuration_import'


describe 'Puppet::Type.type(:zabbix_configuration_import)' do

  before :each do
    @type_instance = Puppet::Type.type(:zabbix_configuration_import).new(:name => 'testimport')
  end

  # type validation checks for path rather than file contents
  it 'should accept absolute pathname for xml_file' do
    @type_instance[:xml_file] = '/here/be/dragon'
    @type_instance[:xml_file] == '/here/be/dragon'
  end

  it 'should not accept non-absolute path for xml_file' do
    expect {
      @type_instance[:xml_file] = 'here/be/dragon'
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
