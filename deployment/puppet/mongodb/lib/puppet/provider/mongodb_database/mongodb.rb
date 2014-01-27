Puppet::Type.type(:mongodb_database).provide(:mongodb) do

  desc "Manages MongoDB database."

  defaultfor :kernel => 'Linux'

  commands :mongo => 'mongo'

  def block_until_mongodb(tries = 10)
    begin
      mongo('--quiet', '--eval', 'db.getMongo()')
    rescue
      debug('MongoDB server not ready, retrying')
      sleep 2
      retry unless (tries -= 1) <= 0
    end
  end

  def create
    mongo(@resource[:name], '--quiet', '--eval', "db.dummyData.insert({\"created_by_puppet\": 1})")
  end

  def destroy
    mongo(@resource[:name], '--quiet', '--eval', 'db.dropDatabase()')
  end

  def exists?
    block_until_mongodb(@resource[:tries])
    mongo("--quiet", "--eval", 'db.getMongo().getDBNames()').split(",").include?(@resource[:name])
  end

end
