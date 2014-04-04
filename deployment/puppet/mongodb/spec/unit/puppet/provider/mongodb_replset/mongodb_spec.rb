#
# Authors: Emilien Macchi <emilien.macchi@enovance.com>
#          Francois Charlier <francois.charlier@enovance.com>
#

require 'spec_helper'

describe Puppet::Type.type(:mongodb_replset).provider(:mongo) do

  valid_members = ['mongo1:27017', 'mongo2:27017', 'mongo3:27017']

  let(:resource) { Puppet::Type.type(:mongodb_replset).new(
    { :ensure        => :present,
      :name          => 'rs_test',
      :members       => valid_members,
      :provider      => :mongo
    }
  )}

  let(:provider) { resource.provider }

  describe 'create' do
    it 'should create a replicaset' do
      provider.stubs(:mongo_command).returns(
        { "info" => "Config now saved locally.  Should come online in about a minute.",
          "ok"   => 1 } )
      provider.create
    end
  end

  describe 'exists?' do
    describe 'when the replicaset is not created' do
      it 'returns false' do
        provider.stubs(:mongo).returns(<<EOT)
{
	"startupStatus" : 3,
	"info" : "run rs.initiate(...) if not yet done for the set",
	"ok" : 0,
	"errmsg" : "can't get local.system.replset config from self or any seed (EMPTYCONFIG)"
}
EOT
        provider.exists?.should be_false
      end
    end

    describe 'when the replicaset is created' do
      it 'returns true' do
        provider.stubs(:mongo).returns(<<EOT)
{
	"set" : "rs_test",
	"date" : ISODate("2014-01-10T18:39:54Z"),
	"myState" : 1,
	"members" : [ ],
	"ok" : 1
}
EOT
        provider.exists?.should be_true
      end
    end

    describe 'when at least one member is configured with another replicaset name' do
      it 'raises an error' do
        provider.stubs(:mongo).returns(<<EOT)
{
	"set" : "rs_another",
	"date" : ISODate("2014-01-10T18:39:54Z"),
	"myState" : 1,
	"members" : [ ],
	"ok" : 1
}
EOT
        expect { provider.exists? }.to raise_error(Puppet::Error, /is already part of another replicaset\.$/)
      end
    end

    describe 'when at least one member is not running with --replSet' do
      it 'raises an error' do
        provider.stubs(:mongo).returns('{ "ok" : 0, "errmsg" : "not running with --replSet" }')
        expect { provider.exists? }.to raise_error(Puppet::Error, /is not supposed to be part of a replicaset\.$/)
      end
    end

    describe 'when no member is available' do
      it 'raises an error' do
        provider.stubs(:mongo_command).raises(Puppet::ExecutionFailure, <<EOT)
Fri Jan 10 20:20:33.995 Error: couldn't connect to server localhost:9999 at src/mongo/shell/mongo.js:147
exception: connect failed
EOT
        expect { provider.exists? }.to raise_error(Puppet::Error, "Can't connect to any member of replicaset #{resource[:name]}.")
      end
    end
  end

  describe 'members' do
    it 'returns the members of a configured replicaset ' do
      provider.stubs(:mongo).returns(<<EOT)
{
	"setName" : "rs_test",
	"ismaster" : true,
	"secondary" : false,
	"hosts" : [
		"mongo1:27017",
		"mongo2:27017",
		"mongo3:27017"
	],
	"primary" : "mongo1:27017",
	"me" : "mongo1:27017",
	"maxBsonObjectSize" : 16777216,
	"maxMessageSizeBytes" : 48000000,
	"localTime" : ISODate("2014-01-10T19:31:51.281Z"),
	"ok" : 1
}
EOT
      provider.members.should =~ valid_members
    end

    it 'raises an error when the master host is not available' do
      provider.stubs(:master_host).returns(nil)
      expect { provider.members }.to raise_error(Puppet::Error, "Can't find master host for replicaset #{resource[:name]}.")
    end

  end

  describe 'members=' do
    it 'adds missing members to an existing replicaset' do
      provider.stubs(:mongo).returns(<<EOT)
{
	"setName" : "rs_test",
	"ismaster" : true,
	"secondary" : false,
	"hosts" : [
		"mongo1:27017"
	],
	"primary" : "mongo1:27017",
	"me" : "mongo1:27017",
	"maxBsonObjectSize" : 16777216,
	"maxMessageSizeBytes" : 48000000,
	"localTime" : ISODate("2014-01-10T19:31:51.281Z"),
	"ok" : 1
}
EOT
      provider.expects('rs_add').times(2)
      provider.members=(valid_members)
    end

    it 'raises an error when the master host is not available' do
      provider.stubs(:master_host).returns(nil)
      expect { provider.members=(valid_members) }.to raise_error(Puppet::Error, "Can't find master host for replicaset #{resource[:name]}.")
    end

  end

end
