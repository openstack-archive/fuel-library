class Puppet::Provider::KeystoneManager < Puppet::Provider

  # parent class that knows how to interact
  # with keystone-manager

  def self.user_hash
    @user_hash ||= build_user_hash
  end

  def self.tenant_hash
    @tenant_hash ||= build_tenant_hash
  end

  def self.role_hash
    @role_hash ||= build_role_hash
  end

  def user_hash
    self.class.user_hash
  end

  def tenant_hash
    self.class.tenant_hash
  end

  def role_hash
    self.class.role_hash
  end

  def property_not_support(property_name)
    raise(Puppet::Error, "Provider #{self.class} does not yet support the ability to update the property #{property_name}")
  end

  private

    def self.build_user_hash
      hash = {}
      list_keystone_objects('user', 4).each do |user|
        validate_enabled(user[2])
        hash[user[1]] = {
          :id => user[0],
          :enabled => user[2],
          :tenant => user[3]
        }
      end
      hash
    end

    def self.build_tenant_hash
      hash = {}
      list_keystone_objects('tenant', 3).each do |tenant|
        validate_enabled(tenant[2])
        hash[tenant[1]] = {
          :id => tenant[0],
          :enabled => tenant[2],
        }
      end
      hash
    end

    def self.build_role_hash
      hash = {}
      list_keystone_objects('role', 4).each do |role|
        Puppet.warning("Found deplicate role #{role[1]}") if hash[role[1]]
        hash[role[1]] = {
          :id => role[0],
          :service_id => role[2],
          :description => role[3]
        }
      end
      hash
    end

    def self.list_keystone_objects(type, number_columns)
      # this assumes that all returned objects are of the form
      # id, name, enabled_state, OTHER
      list = keystone_manage(type, 'list').split("\n")[5..-2].collect do |line|
        row = line.split(/\s*\|\s*/)[1..-1]
        if row.size != number_columns
          raise(Puppet::Error, "Expected #{number_columns} columns for #{type} row, found #{list.size}. Line #{line}")
        end
        row
      end
      list
    end

    def self.validate_enabled(value)
      unless value == 'True' || value == 'False'
        raise(Puppet::Error, "Invalid value #{value} for enabled attribute")
      end
    end
end
