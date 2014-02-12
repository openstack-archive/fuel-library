$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../../../lib/ruby/")
require "zabbix"

describe "Zabbix" do
  it "should not fail when connecting to the server" do

    Puppet.settings[:config]= "#{File.dirname(__FILE__)}/../../../tests/etc/puppet.conf"
    
    extend Zabbix
    zbx
  end
end