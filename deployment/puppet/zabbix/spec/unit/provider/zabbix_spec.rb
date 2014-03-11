require 'puppet'
require 'spec_helper'
require 'puppet/provider/zabbix'

cls = Puppet::Provider::Zabbix

describe Puppet::Provider::Zabbix do

  describe 'when making an API request' do

    it 'should fail if Zabbix returns error' do
      mock = {'error' => {'code' => 0,
                          'message' => 'test error',
                          'data' => 'not a real error'}}
      Puppet::Provider::Zabbix.expects(:make_request).returns(mock)
      fake_api = {'endpoint' => 'http://localhost',
                  'username' => 'Admin',
                  'password' => 'zabbix'}
      expect {
        cls.api_request(fake_api, {})
      }.to raise_error(Puppet::Error, /Zabbix API returned/)
    end

    it 'should return "result" sub-hash from json returned by API' do
      mock = {'result' => {'code' => 0,
                          'message' => 'test result',
                          'data' => 'just a test'}}
      Puppet::Provider::Zabbix.expects(:make_request).returns(mock)
      fake_api = {'endpoint' => 'http://localhost',
                  'username' => 'Admin',
                  'password' => 'zabbix'}
      cls.api_request(fake_api, {}) == {'code' => 0,
                                        'message' => 'test result',
                                        'data' => 'just a test'}
    end

  end

end
