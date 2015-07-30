require 'spec_helper'
require 'json'

describe Puppet::Type.type(:mongodb_user).provider(:mongodb) do

  let(:raw_users) do
    [
      { '_id' => 'admin.root', 'user' => 'root', 'db' => 'admin', 'credentials' => { 'MONGODB-CR' => 'pass' }, 'roles' => [ { 'role' => 'role2', 'db' => 'admin' },  { 'role' => 'role1', 'db' => 'admin' } ] }
    ].to_json
  end

  let(:parsed_users) { %w(root) }

  let(:resource) { Puppet::Type.type(:mongodb_user).new(
    { :ensure        => :present,
      :name          => 'new_user',
      :database      => 'new_database',
      :password_hash => 'pass',
      :roles         => ['role1', 'role2'],
      :provider      => described_class.name
    }
  )}

  let(:provider) { resource.provider }

  before :each do
     provider.class.stubs(:mongo_eval).with('rs.slaveOk(); printjson(db.system.users.find().toArray())').returns(raw_users)
     provider.class.stubs(:mongo_version).returns('2.6.x')
  end

  let(:instance) { provider.class.instances.first }

  describe 'self.instances' do
    it 'returns an array of users' do
      usernames = provider.class.instances.collect {|x| x.username }
      expect(parsed_users).to match_array(usernames)
    end
  end

  describe 'create' do
    it 'creates a user' do
      cmd_json=<<-EOS.gsub(/^\s*/, '').gsub(/$\n/, '')
      {
        "createUser": "new_user",
        "pwd": "pass",
        "customData": {"createdBy": "Puppet Mongodb_user['new_user']"},
        "roles": ["role1","role2"],
        "digestPassword": false
      }
      EOS

      provider.expects(:mongo_eval).with("db.runCommand(#{cmd_json})", 'new_database')
      provider.create
    end
  end

  describe 'destroy' do
    it 'removes a user' do
      provider.expects(:mongo_eval).with("db.dropUser('new_user')")
      provider.destroy
    end
  end

  describe 'exists?' do
    it 'checks if user exists' do
      provider.exists?.should eql false
    end
  end

  describe 'password_hash' do
    it 'returns a password_hash' do
      instance.password_hash.should == "pass"
    end
  end

  describe 'password_hash=' do
    it 'changes a password_hash' do
      cmd_json=<<-EOS.gsub(/^\s*/, '').gsub(/$\n/, '')
      {
          "updateUser": "new_user",
          "pwd": "pass",
          "digestPassword": false
      }
      EOS
      provider.expects(:mongo_eval).
        with("db.runCommand(#{cmd_json})", 'new_database')
      provider.password_hash=("newpass")
    end
  end

  describe 'roles' do
    it 'returns a sorted roles' do
      instance.roles.should == ['role1', 'role2']
    end
  end

  describe 'roles=' do
    it 'changes nothing' do
      provider.expects(:mongo_eval).times(0)
      provider.roles=(['role1', 'role2'])
    end

    it 'grant a role' do
      provider.expects(:mongo_eval).with("db.getSiblingDB('new_database').grantRolesToUser('new_user', [\"role3\"])")
      provider.roles=(['role1', 'role2', 'role3'])
    end

    it 'revokes a role' do
      provider.expects(:mongo_eval).
        with("db.getSiblingDB('new_database').revokeRolesFromUser('new_user', [\"role1\"])")
      provider.roles=(['role2'])
    end

    it 'exchanges a role' do
      provider.expects(:mongo_eval).
        with("db.getSiblingDB('new_database').revokeRolesFromUser('new_user', [\"role1\"])")
      provider.expects(:mongo_eval).
        with("db.getSiblingDB('new_database').grantRolesToUser('new_user', [\"role3\"])")

      provider.roles=(['role2', 'role3'])
    end
  end

end
