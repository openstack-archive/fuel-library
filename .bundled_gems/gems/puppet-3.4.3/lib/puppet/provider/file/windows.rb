Puppet::Type.type(:file).provide :windows do
  desc "Uses Microsoft Windows functionality to manage file ownership and permissions."

  confine :operatingsystem => :windows
  has_feature :manages_symlinks if Puppet.features.manages_symlinks?

  include Puppet::Util::Warnings

  if Puppet.features.microsoft_windows?
    require 'puppet/util/windows'
    require 'puppet/util/adsi'
    include Puppet::Util::Windows::Security
  end

  # Determine if the account is valid, and if so, return the UID
  def name2id(value)
    Puppet::Util::Windows::Security.name_to_sid(value)
  end

  # If it's a valid SID, get the name. Otherwise, it's already a name,
  # so just return it.
  def id2name(id)
    if Puppet::Util::Windows::Security.valid_sid?(id)
      Puppet::Util::Windows::Security.sid_to_name(id)
    else
      id
    end
  end

  # We use users and groups interchangeably, so use the same methods for both
  # (the type expects different methods, so we have to oblige).
  alias :uid2name :id2name
  alias :gid2name :id2name

  alias :name2gid :name2id
  alias :name2uid :name2id

  def owner
    return :absent unless resource.stat
    get_owner(resource[:path])
  end

  def owner=(should)
    begin
      path = resource[:links] == :manage ? file.path.to_s : file.readlink

      set_owner(should, path)
    rescue => detail
      raise Puppet::Error, "Failed to set owner to '#{should}': #{detail}"
    end
  end

  def group
    return :absent unless resource.stat
    get_group(resource[:path])
  end

  def group=(should)
    begin
      path = resource[:links] == :manage ? file.path.to_s : file.readlink

      set_group(should, path)
    rescue => detail
      raise Puppet::Error, "Failed to set group to '#{should}': #{detail}"
    end
  end

  def mode
    if resource.stat
      mode = get_mode(resource[:path])
      mode ? mode.to_s(8) : :absent
    else
      :absent
    end
  end

  def mode=(value)
    begin
      set_mode(value.to_i(8), resource[:path])
    rescue => detail
      error = Puppet::Error.new("failed to set mode #{mode} on #{resource[:path]}: #{detail.message}")
      error.set_backtrace detail.backtrace
      raise error
    end
    :file_changed
  end

  def validate
    if [:owner, :group, :mode].any?{|p| resource[p]} and !supports_acl?(resource[:path])
      resource.fail("Can only manage owner, group, and mode on filesystems that support Windows ACLs, such as NTFS")
    end
  end

  attr_reader :file
  private
  def file
    @file ||= Puppet::FileSystem::File.new(resource[:path])
  end
end
