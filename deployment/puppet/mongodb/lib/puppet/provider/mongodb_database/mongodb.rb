require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mongodb'))
Puppet::Type.type(:mongodb_database).provide(:mongodb, :parent => Puppet::Provider::Mongodb) do

  desc "Manages MongoDB database."

  defaultfor :kernel => 'Linux'

  def self.instances
    require 'json'
    if mongo_eval('db.isMaster().ismaster').to_s.strip == 'true'
      dbs = JSON.parse mongo_eval('printjson(db.getMongo().getDBs())')

      dbs['databases'].collect do |db|
        new(:name   => db['name'],
            :ensure => :present)
      end
    else
      Puppet.warning 'Impossible to get databases from slave'
      dbs = []
    end
  end

  # Assign prefetched dbs based on name.
  def self.prefetch(resources)
    dbs = instances
    resources.keys.each do |name|
      if provider = dbs.find { |db| db.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    if mongo_eval('db.isMaster().ismaster').to_s.strip == 'true'
      mongo_eval('db.dummyData.insert({"created_by_puppet": 1})', @resource[:name])
    end
  end

  def destroy
    if mongo_eval('db.isMaster().ismaster').to_s.strip == 'true'
      mongo_eval('db.dropDatabase()', @resource[:name])
    end
  end

  def exists?
    !(@property_hash[:ensure] == :absent or @property_hash[:ensure].nil?)
  end

end
