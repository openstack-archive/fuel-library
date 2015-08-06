module Puppet::Util::ADSI
  class << self
    def connectable?(uri)
      begin
        !! connect(uri)
      rescue
        false
      end
    end

    def connect(uri)
      begin
        WIN32OLE.connect(uri)
      rescue Exception => e
        raise Puppet::Error.new( "ADSI connection error: #{e}" )
      end
    end

    def create(name, resource_type)
      Puppet::Util::ADSI.connect(computer_uri).Create(resource_type, name)
    end

    def delete(name, resource_type)
      Puppet::Util::ADSI.connect(computer_uri).Delete(resource_type, name)
    end

    def computer_name
      unless @computer_name
        buf = " " * 128
        Win32API.new('kernel32', 'GetComputerName', ['P','P'], 'I').call(buf, buf.length.to_s)
        @computer_name = buf.unpack("A*")[0]
      end
      @computer_name
    end

    def computer_uri(host = '.')
      "WinNT://#{host}"
    end

    def wmi_resource_uri( host = '.' )
      "winmgmts:{impersonationLevel=impersonate}!//#{host}/root/cimv2"
    end

    def sid_uri(sid)
      raise Puppet::Error.new( "Must use a valid SID object" ) if !sid.kind_of?(Win32::Security::SID)
      "WinNT://#{sid.to_s}"
    end

    def uri(resource_name, resource_type, host = '.')
      "#{computer_uri(host)}/#{resource_name},#{resource_type}"
    end

    def wmi_connection
      connect(wmi_resource_uri)
    end

    def execquery(query)
      wmi_connection.execquery(query)
    end

    def sid_for_account(name)
      Puppet.deprecation_warning "Puppet::Util::ADSI.sid_for_account is deprecated and will be removed in 3.0, use Puppet::Util::Windows::SID.name_to_sid instead."

      Puppet::Util::Windows::Security.name_to_sid(name)
    end
  end

  class User
    extend Enumerable

    attr_accessor :native_user
    attr_reader :name, :sid
    def initialize(name, native_user = nil)
      @name = name
      @native_user = native_user
    end

    def self.parse_name(name)
      if name =~ /\//
        raise Puppet::Error.new( "Value must be in DOMAIN\\user style syntax" )
      end

      matches = name.scan(/((.*)\\)?(.*)/)
      domain = matches[0][1] || '.'
      account = matches[0][2]

      return account, domain
    end

    def native_user
      @native_user ||= Puppet::Util::ADSI.connect(self.class.uri(*self.class.parse_name(@name)))
    end

    def sid
      @sid ||= Puppet::Util::Windows::Security.octet_string_to_sid_object(native_user.objectSID)
    end

    def self.uri(name, host = '.')
      host = '.' if ['NT AUTHORITY', 'BUILTIN', Socket.gethostname].include?(host)

      Puppet::Util::ADSI.uri(name, 'user', host)
    end

    def uri
      self.class.uri(sid.account, sid.domain)
    end

    def self.logon(name, password)
      Puppet::Util::Windows::User.password_is?(name, password)
    end

    def [](attribute)
      native_user.Get(attribute)
    end

    def []=(attribute, value)
      native_user.Put(attribute, value)
    end

    def commit
      begin
        native_user.SetInfo unless native_user.nil?
      rescue Exception => e
        raise Puppet::Error.new( "User update failed: #{e}" )
      end
      self
    end

    def password_is?(password)
      self.class.logon(name, password)
    end

    def add_flag(flag_name, value)
      flag = native_user.Get(flag_name) rescue 0

      native_user.Put(flag_name, flag | value)

      commit
    end

    def password=(password)
      native_user.SetPassword(password)
      commit
      fADS_UF_DONT_EXPIRE_PASSWD = 0x10000
      add_flag("UserFlags", fADS_UF_DONT_EXPIRE_PASSWD)
    end

    def groups
      # WIN32OLE objects aren't enumerable, so no map
      groups = []
      native_user.Groups.each {|g| groups << g.Name} rescue nil
      groups
    end

    def add_to_groups(*group_names)
      group_names.each do |group_name|
        Puppet::Util::ADSI::Group.new(group_name).add_member_sids(sid)
      end
    end
    alias add_to_group add_to_groups

    def remove_from_groups(*group_names)
      group_names.each do |group_name|
        Puppet::Util::ADSI::Group.new(group_name).remove_member_sids(sid)
      end
    end
    alias remove_from_group remove_from_groups

    def set_groups(desired_groups, minimum = true)
      return if desired_groups.nil? or desired_groups.empty?

      desired_groups = desired_groups.split(',').map(&:strip)

      current_groups = self.groups

      # First we add the user to all the groups it should be in but isn't
      groups_to_add = desired_groups - current_groups
      add_to_groups(*groups_to_add)

      # Then we remove the user from all groups it is in but shouldn't be, if
      # that's been requested
      groups_to_remove = current_groups - desired_groups
      remove_from_groups(*groups_to_remove) unless minimum
    end

    def self.create(name)
      # Windows error 1379: The specified local group already exists.
      raise Puppet::Error.new( "Cannot create user if group '#{name}' exists." ) if Puppet::Util::ADSI::Group.exists? name
      new(name, Puppet::Util::ADSI.create(name, 'user'))
    end

    def self.exists?(name)
      Puppet::Util::ADSI::connectable?(User.uri(*User.parse_name(name)))
    end

    def self.delete(name)
      Puppet::Util::ADSI.delete(name, 'user')
    end

    def self.each(&block)
      wql = Puppet::Util::ADSI.execquery('select name from win32_useraccount where localaccount = "TRUE"')

      users = []
      wql.each do |u|
        users << new(u.name)
      end

      users.each(&block)
    end
  end

  class UserProfile
    def self.delete(sid)
      begin
        Puppet::Util::ADSI.wmi_connection.Delete("Win32_UserProfile.SID='#{sid}'")
      rescue => e
        # http://social.technet.microsoft.com/Forums/en/ITCG/thread/0f190051-ac96-4bf1-a47f-6b864bfacee5
        # Prior to Vista SP1, there's no builtin way to programmatically
        # delete user profiles (except for delprof.exe). So try to delete
        # but warn if we fail
        raise e unless e.message.include?('80041010')

        Puppet.warning "Cannot delete user profile for '#{sid}' prior to Vista SP1"
      end
    end
  end

  class Group
    extend Enumerable

    attr_accessor :native_group
    attr_reader :name
    def initialize(name, native_group = nil)
      @name = name
      @native_group = native_group
    end

    def uri
      self.class.uri(name)
    end

    def self.uri(name, host = '.')
      Puppet::Util::ADSI.uri(name, 'group', host)
    end

    def native_group
      @native_group ||= Puppet::Util::ADSI.connect(uri)
    end

    def commit
      begin
        native_group.SetInfo unless native_group.nil?
      rescue Exception => e
        raise Puppet::Error.new( "Group update failed: #{e}" )
      end
      self
    end

    def self.name_sid_hash(names)
      return [] if names.nil? or names.empty?

      sids = names.map do |name|
        sid = Puppet::Util::Windows::Security.name_to_sid_object(name)
        raise Puppet::Error.new( "Could not resolve username: #{name}" ) if !sid
        [sid.to_s, sid]
      end

      Hash[ sids ]
    end

    def add_members(*names)
      Puppet.deprecation_warning('Puppet::Util::ADSI::Group#add_members is deprecated; please use Puppet::Util::ADSI::Group#add_member_sids')
      sids = self.class.name_sid_hash(names)
      add_member_sids(*sids.values)
    end
    alias add_member add_members

    def remove_members(*names)
      Puppet.deprecation_warning('Puppet::Util::ADSI::Group#remove_members is deprecated; please use Puppet::Util::ADSI::Group#remove_member_sids')
      sids = self.class.name_sid_hash(names)
      remove_member_sids(*sids.values)
    end
    alias remove_member remove_members

    def add_member_sids(*sids)
      sids.each do |sid|
        native_group.Add(Puppet::Util::ADSI.sid_uri(sid))
      end
    end

    def remove_member_sids(*sids)
      sids.each do |sid|
        native_group.Remove(Puppet::Util::ADSI.sid_uri(sid))
      end
    end

    def members
      # WIN32OLE objects aren't enumerable, so no map
      members = []
      native_group.Members.each {|m| members << m.Name}
      members
    end

    def member_sids
      sids = []
      native_group.Members.each do |m|
        sids << Puppet::Util::Windows::Security.octet_string_to_sid_object(m.objectSID)
      end
      sids
    end

    def set_members(desired_members)
      return if desired_members.nil? or desired_members.empty?

      current_hash = Hash[ self.member_sids.map { |sid| [sid.to_s, sid] } ]
      desired_hash = self.class.name_sid_hash(desired_members)

      # First we add all missing members
      members_to_add = (desired_hash.keys - current_hash.keys).map { |sid| desired_hash[sid] }
      add_member_sids(*members_to_add)

      # Then we remove all extra members
      members_to_remove = (current_hash.keys - desired_hash.keys).map { |sid| current_hash[sid] }
      remove_member_sids(*members_to_remove)
    end

    def self.create(name)
      # Windows error 2224: The account already exists.
      raise Puppet::Error.new( "Cannot create group if user '#{name}' exists." ) if Puppet::Util::ADSI::User.exists? name
      new(name, Puppet::Util::ADSI.create(name, 'group'))
    end

    def self.exists?(name)
      Puppet::Util::ADSI.connectable?(Group.uri(name))
    end

    def self.delete(name)
      Puppet::Util::ADSI.delete(name, 'group')
    end

    def self.each(&block)
      wql = Puppet::Util::ADSI.execquery( 'select name from win32_group where localaccount = "TRUE"' )

      groups = []
      wql.each do |g|
        groups << new(g.name)
      end

      groups.each(&block)
    end
  end
end
