# This class maps POSIX owner, group, and modes to the Windows
# security model, and back.
#
# The primary goal of this mapping is to ensure that owner, group, and
# modes can be round-tripped in a consistent and deterministic
# way. Otherwise, Puppet might think file resources are out-of-sync
# every time it runs. A secondary goal is to provide equivalent
# permissions for common use-cases. For example, setting the owner to
# "Administrators", group to "Users", and mode to 750 (which also
# denies access to everyone else.
#
# There are some well-known problems mapping windows and POSIX
# permissions due to differences between the two security
# models. Search for "POSIX permission mapping leak". In POSIX, access
# to a file is determined solely based on the most specific class
# (user, group, other). So a mode of 460 would deny write access to
# the owner even if they are a member of the group. But in Windows,
# the entire access control list is walked until the user is
# explicitly denied or allowed (denied take precedence, and if neither
# occurs they are denied). As a result, a user could be allowed access
# based on their group membership. To solve this problem, other people
# have used deny access control entries to more closely model POSIX,
# but this introduces a lot of complexity.
#
# In general, this implementation only supports "typical" permissions,
# where group permissions are a subset of user, and other permissions
# are a subset of group, e.g. 754, but not 467.  However, there are
# some Windows quirks to be aware of.
#
# * The owner can be either a user or group SID, and most system files
#   are owned by the Administrators group.
# * The group can be either a user or group SID.
# * Unexpected results can occur if the owner and group are the
#   same, but the user and group classes are different, e.g. 750. In
#   this case, it is not possible to allow write access to the owner,
#   but not the group. As a result, the actual permissions set on the
#   file would be 770.
# * In general, only privileged users can set the owner, group, or
#   change the mode for files they do not own. In 2003, the user must
#   be a member of the Administrators group. In Vista/2008, the user
#   must be running with elevated privileges.
# * A file/dir can be deleted by anyone with the DELETE access right
#   OR by anyone that has the FILE_DELETE_CHILD access right for the
#   parent. See http://support.microsoft.com/kb/238018. But on Unix,
#   the user must have write access to the file/dir AND execute access
#   to all of the parent path components.
# * Many access control entries are inherited from parent directories,
#   and it is common for file/dirs to have more than 3 entries,
#   e.g. Users, Power Users, Administrators, SYSTEM, etc, which cannot
#   be mapped into the 3 class POSIX model. The get_mode method will
#   set the S_IEXTRA bit flag indicating that an access control entry
#   was found whose SID is neither the owner, group, or other. This
#   enables Puppet to detect when file/dirs are out-of-sync,
#   especially those that Puppet did not create, but is attempting
#   to manage.
# * A special case of this is S_ISYSTEM_MISSING, which is set when the
#   SYSTEM permissions are *not* present on the DACL.
# * On Unix, the owner and group can be modified without changing the
#   mode. But on Windows, an access control entry specifies which SID
#   it applies to. As a result, the set_owner and set_group methods
#   automatically rebuild the access control list based on the new
#   (and different) owner or group.

require 'puppet/util/windows'
require 'pathname'
require 'ffi'

require 'win32/security'

require 'windows/file'
require 'windows/handle'
require 'windows/security'
require 'windows/process'
require 'windows/memory'
require 'windows/msvcrt/buffer'
require 'windows/volume'

module Puppet::Util::Windows::Security
  include ::Windows::File
  include ::Windows::Handle
  include ::Windows::Security
  include ::Windows::Process
  include ::Windows::Memory
  include ::Windows::MSVCRT::Buffer
  include ::Windows::Volume

  include Puppet::Util::Windows::SID

  extend Puppet::Util::Windows::Security

  # file modes
  S_IRUSR = 0000400
  S_IRGRP = 0000040
  S_IROTH = 0000004
  S_IWUSR = 0000200
  S_IWGRP = 0000020
  S_IWOTH = 0000002
  S_IXUSR = 0000100
  S_IXGRP = 0000010
  S_IXOTH = 0000001
  S_IRWXU = 0000700
  S_IRWXG = 0000070
  S_IRWXO = 0000007
  S_ISVTX = 0001000
  S_IEXTRA = 02000000  # represents an extra ace
  S_ISYSTEM_MISSING = 04000000

  # constants that are missing from Windows::Security
  PROTECTED_DACL_SECURITY_INFORMATION   = 0x80000000
  UNPROTECTED_DACL_SECURITY_INFORMATION = 0x20000000
  NO_INHERITANCE = 0x0
  SE_DACL_PROTECTED = 0x1000

  # Set the owner of the object referenced by +path+ to the specified
  # +owner_sid+.  The owner sid should be of the form "S-1-5-32-544"
  # and can either be a user or group.  Only a user with the
  # SE_RESTORE_NAME privilege in their process token can overwrite the
  # object's owner to something other than the current user.
  def set_owner(owner_sid, path)
    sd = get_security_descriptor(path)

    if owner_sid != sd.owner
      sd.owner = owner_sid
      set_security_descriptor(path, sd)
    end
  end

  # Get the owner of the object referenced by +path+.  The returned
  # value is a SID string, e.g. "S-1-5-32-544".  Any user with read
  # access to an object can get the owner. Only a user with the
  # SE_BACKUP_NAME privilege in their process token can get the owner
  # for objects they do not have read access to.
  def get_owner(path)
    return unless supports_acl?(path)

    get_security_descriptor(path).owner
  end

  # Set the owner of the object referenced by +path+ to the specified
  # +group_sid+.  The group sid should be of the form "S-1-5-32-544"
  # and can either be a user or group.  Any user with WRITE_OWNER
  # access to the object can change the group (regardless of whether
  # the current user belongs to that group or not).
  def set_group(group_sid, path)
    sd = get_security_descriptor(path)

    if group_sid != sd.group
      sd.group = group_sid
      set_security_descriptor(path, sd)
    end
  end

  # Get the group of the object referenced by +path+.  The returned
  # value is a SID string, e.g. "S-1-5-32-544".  Any user with read
  # access to an object can get the group. Only a user with the
  # SE_BACKUP_NAME privilege in their process token can get the group
  # for objects they do not have read access to.
  def get_group(path)
    return unless supports_acl?(path)

    get_security_descriptor(path).group
  end

  def supports_acl?(path)
    flags = 0.chr * 4

    root = Pathname.new(path).enum_for(:ascend).to_a.last.to_s
    # 'A trailing backslash is required'
    root = "#{root}\\" unless root =~ /[\/\\]$/
    unless GetVolumeInformation(root, nil, 0, nil, nil, flags, nil, 0)
      raise Puppet::Util::Windows::Error.new("Failed to get volume information")
    end

    (flags.unpack('L')[0] & Windows::File::FILE_PERSISTENT_ACLS) != 0
  end

  def get_attributes(path)
    attributes = GetFileAttributes(path)

    raise Puppet::Util::Windows::Error.new("Failed to get file attributes") if attributes == INVALID_FILE_ATTRIBUTES

    attributes
  end

  def add_attributes(path, flags)
    oldattrs = get_attributes(path)

    if (oldattrs | flags) != oldattrs
      set_attributes(path, oldattrs | flags)
    end
  end

  def remove_attributes(path, flags)
    oldattrs = get_attributes(path)

    if (oldattrs & ~flags) != oldattrs
      set_attributes(path, oldattrs & ~flags)
    end
  end

  def set_attributes(path, flags)
    raise Puppet::Util::Windows::Error.new("Failed to set file attributes") unless SetFileAttributes(path, flags)
  end

  MASK_TO_MODE = {
    FILE_GENERIC_READ => S_IROTH,
    FILE_GENERIC_WRITE => S_IWOTH,
    (FILE_GENERIC_EXECUTE & ~FILE_READ_ATTRIBUTES) => S_IXOTH
  }

  def get_aces_for_path_by_sid(path, sid)
    get_security_descriptor(path).dacl.select { |ace| ace.sid == sid }
  end

  # Get the mode of the object referenced by +path+.  The returned
  # integer value represents the POSIX-style read, write, and execute
  # modes for the user, group, and other classes, e.g. 0640.  Any user
  # with read access to an object can get the mode. Only a user with
  # the SE_BACKUP_NAME privilege in their process token can get the
  # mode for objects they do not have read access to.
  def get_mode(path)
    return unless supports_acl?(path)

    well_known_world_sid = Win32::Security::SID::Everyone
    well_known_nobody_sid = Win32::Security::SID::Nobody
    well_known_system_sid = Win32::Security::SID::LocalSystem

    mode = S_ISYSTEM_MISSING

    sd = get_security_descriptor(path)
    sd.dacl.each do |ace|
      next if ace.inherit_only?

      case ace.sid
      when sd.owner
        MASK_TO_MODE.each_pair do |k,v|
          if (ace.mask & k) == k
            mode |= (v << 6)
          end
        end
      when sd.group
        MASK_TO_MODE.each_pair do |k,v|
          if (ace.mask & k) == k
            mode |= (v << 3)
          end
        end
      when well_known_world_sid
        MASK_TO_MODE.each_pair do |k,v|
          if (ace.mask & k) == k
            mode |= (v << 6) | (v << 3) | v
          end
        end
        if File.directory?(path) && (ace.mask & (FILE_WRITE_DATA | FILE_EXECUTE | FILE_DELETE_CHILD)) == (FILE_WRITE_DATA | FILE_EXECUTE)
          mode |= S_ISVTX;
        end
      when well_known_nobody_sid
        if (ace.mask & FILE_APPEND_DATA).nonzero?
          mode |= S_ISVTX
        end
      when well_known_system_sid
      else
        #puts "Warning, unable to map SID into POSIX mode: #{ace.sid}"
        mode |= S_IEXTRA
      end

      if ace.sid == well_known_system_sid
        mode &= ~S_ISYSTEM_MISSING
      end

      # if owner and group the same, then user and group modes are the OR of both
      if sd.owner == sd.group
        mode |= ((mode & S_IRWXG) << 3) | ((mode & S_IRWXU) >> 3)
        #puts "owner: #{sd.group}, 0x#{ace.mask.to_s(16)}, #{mode.to_s(8)}"
      end
    end

    #puts "get_mode: #{mode.to_s(8)}"
    mode
  end

  MODE_TO_MASK = {
    S_IROTH => FILE_GENERIC_READ,
    S_IWOTH => FILE_GENERIC_WRITE,
    S_IXOTH => (FILE_GENERIC_EXECUTE & ~FILE_READ_ATTRIBUTES),
  }

  # Set the mode of the object referenced by +path+ to the specified
  # +mode+.  The mode should be specified as POSIX-stye read, write,
  # and execute modes for the user, group, and other classes,
  # e.g. 0640. The sticky bit, S_ISVTX, is supported, but is only
  # meaningful for directories. If set, group and others are not
  # allowed to delete child objects for which they are not the owner.
  # By default, the DACL is set to protected, meaning it does not
  # inherit access control entries from parent objects. This can be
  # changed by setting +protected+ to false. The owner of the object
  # (with READ_CONTROL and WRITE_DACL access) can always change the
  # mode. Only a user with the SE_BACKUP_NAME and SE_RESTORE_NAME
  # privileges in their process token can change the mode for objects
  # that they do not have read and write access to.
  def set_mode(mode, path, protected = true)
    sd = get_security_descriptor(path)
    well_known_world_sid = Win32::Security::SID::Everyone
    well_known_nobody_sid = Win32::Security::SID::Nobody
    well_known_system_sid = Win32::Security::SID::LocalSystem

    owner_allow = STANDARD_RIGHTS_ALL  | FILE_READ_ATTRIBUTES | FILE_WRITE_ATTRIBUTES
    group_allow = STANDARD_RIGHTS_READ | FILE_READ_ATTRIBUTES | SYNCHRONIZE
    other_allow = STANDARD_RIGHTS_READ | FILE_READ_ATTRIBUTES | SYNCHRONIZE
    nobody_allow = 0
    system_allow = 0

    MODE_TO_MASK.each do |k,v|
      if ((mode >> 6) & k) == k
        owner_allow |= v
      end
      if ((mode >> 3) & k) == k
        group_allow |= v
      end
      if (mode & k) == k
        other_allow |= v
      end
    end

    if (mode & S_ISVTX).nonzero?
      nobody_allow |= FILE_APPEND_DATA;
    end

    # caller is NOT managing SYSTEM by using group or owner, so set to FULL
    if ! [sd.owner, sd.group].include? well_known_system_sid
      # we don't check S_ISYSTEM_MISSING bit, but automatically carry over existing SYSTEM perms
      # by default set SYSTEM perms to full
      system_allow = FILE_ALL_ACCESS
    end

    isdir = File.directory?(path)

    if isdir
      if (mode & (S_IWUSR | S_IXUSR)) == (S_IWUSR | S_IXUSR)
        owner_allow |= FILE_DELETE_CHILD
      end
      if (mode & (S_IWGRP | S_IXGRP)) == (S_IWGRP | S_IXGRP) && (mode & S_ISVTX) == 0
        group_allow |= FILE_DELETE_CHILD
      end
      if (mode & (S_IWOTH | S_IXOTH)) == (S_IWOTH | S_IXOTH) && (mode & S_ISVTX) == 0
        other_allow |= FILE_DELETE_CHILD
      end
    end

    # if owner and group the same, then map group permissions to the one owner ACE
    isownergroup = sd.owner == sd.group
    if isownergroup
      owner_allow |= group_allow
    end

    # if any ACE allows write, then clear readonly bit, but do this before we overwrite
    # the DACl and lose our ability to set the attribute
    if ((owner_allow | group_allow | other_allow ) & FILE_WRITE_DATA) == FILE_WRITE_DATA
      remove_attributes(path, FILE_ATTRIBUTE_READONLY)
    end

    dacl = Puppet::Util::Windows::AccessControlList.new
    dacl.allow(sd.owner, owner_allow)
    unless isownergroup
      dacl.allow(sd.group, group_allow)
    end
    dacl.allow(well_known_world_sid, other_allow)
    dacl.allow(well_known_nobody_sid, nobody_allow)

    # TODO: system should be first?
    dacl.allow(well_known_system_sid, system_allow)

    # add inherit-only aces for child dirs and files that are created within the dir
    if isdir
      inherit = INHERIT_ONLY_ACE | CONTAINER_INHERIT_ACE
      dacl.allow(Win32::Security::SID::CreatorOwner, owner_allow, inherit)
      dacl.allow(Win32::Security::SID::CreatorGroup, group_allow, inherit)

      inherit = INHERIT_ONLY_ACE |  OBJECT_INHERIT_ACE
      dacl.allow(Win32::Security::SID::CreatorOwner, owner_allow & ~FILE_EXECUTE, inherit)
      dacl.allow(Win32::Security::SID::CreatorGroup, group_allow & ~FILE_EXECUTE, inherit)
    end

    new_sd = Puppet::Util::Windows::SecurityDescriptor.new(sd.owner, sd.group, dacl, protected)
    set_security_descriptor(path, new_sd)

    nil
  end

  def add_access_allowed_ace(acl, mask, sid, inherit = nil)
    inherit ||= NO_INHERITANCE

    string_to_sid_ptr(sid) do |sid_ptr|
      raise Puppet::Util::Windows::Error.new("Invalid SID") unless IsValidSid(sid_ptr)

      unless AddAccessAllowedAceEx(acl, ACL_REVISION, inherit, mask, sid_ptr)
        raise Puppet::Util::Windows::Error.new("Failed to add access control entry")
      end
    end
  end

  def add_access_denied_ace(acl, mask, sid)
    string_to_sid_ptr(sid) do |sid_ptr|
      raise Puppet::Util::Windows::Error.new("Invalid SID") unless IsValidSid(sid_ptr)

      unless AddAccessDeniedAce(acl, ACL_REVISION, mask, sid_ptr)
        raise Puppet::Util::Windows::Error.new("Failed to add access control entry")
      end
    end
  end

  def parse_dacl(dacl_ptr)
    # REMIND: need to handle NULL DACL
    raise Puppet::Util::Windows::Error.new("Invalid DACL") unless IsValidAcl(dacl_ptr)

    # ACL structure, size and count are the important parts. The
    # size includes both the ACL structure and all the ACEs.
    #
    # BYTE AclRevision
    # BYTE Padding1
    # WORD AclSize
    # WORD AceCount
    # WORD Padding2
    acl_buf = 0.chr * 8
    memcpy(acl_buf, dacl_ptr, acl_buf.size)
    ace_count = acl_buf.unpack('CCSSS')[3]

    dacl = Puppet::Util::Windows::AccessControlList.new

    # deny all
    return dacl if ace_count == 0

    0.upto(ace_count - 1) do |i|
      ace_ptr = [0].pack('L')

      next unless GetAce(dacl_ptr, i, ace_ptr)

      # ACE structures vary depending on the type. All structures
      # begin with an ACE header, which specifies the type, flags
      # and size of what follows. We are only concerned with
      # ACCESS_ALLOWED_ACE and ACCESS_DENIED_ACEs, which have the
      # same structure:
      #
      # BYTE  C AceType
      # BYTE  C AceFlags
      # WORD  S AceSize
      # DWORD L ACCESS_MASK
      # DWORD L Sid
      # ..      ...
      # DWORD L Sid

      ace_buf = 0.chr * 8
      memcpy(ace_buf, ace_ptr.unpack('L')[0], ace_buf.size)

      ace_type, ace_flags, size, mask = ace_buf.unpack('CCSL')

      case ace_type
      when ACCESS_ALLOWED_ACE_TYPE
        sid_ptr = ace_ptr.unpack('L')[0] + 8 # address of ace_ptr->SidStart
        raise Puppet::Util::Windows::Error.new("Failed to read DACL, invalid SID") unless IsValidSid(sid_ptr)
        sid = sid_ptr_to_string(sid_ptr)
        dacl.allow(sid, mask, ace_flags)
      when ACCESS_DENIED_ACE_TYPE
        sid_ptr = ace_ptr.unpack('L')[0] + 8 # address of ace_ptr->SidStart
        raise Puppet::Util::Windows::Error.new("Failed to read DACL, invalid SID") unless IsValidSid(sid_ptr)
        sid = sid_ptr_to_string(sid_ptr)
        dacl.deny(sid, mask, ace_flags)
      else
        Puppet.warning "Unsupported access control entry type: 0x#{ace_type.to_s(16)}"
      end
    end

    dacl
  end

  # Open an existing file with the specified access mode, and execute a
  # block with the opened file HANDLE.
  def open_file(path, access)
    handle = CreateFile(
             path,
             access,
             FILE_SHARE_READ | FILE_SHARE_WRITE,
             0, # security_attributes
             OPEN_EXISTING,
             FILE_FLAG_OPEN_REPARSE_POINT | FILE_FLAG_BACKUP_SEMANTICS,
             0) # template
    raise Puppet::Util::Windows::Error.new("Failed to open '#{path}'") if handle == INVALID_HANDLE_VALUE
    begin
      yield handle
    ensure
      CloseHandle(handle)
    end
  end

  # Execute a block with the specified privilege enabled
  def with_privilege(privilege)
    set_privilege(privilege, true)
    yield
  ensure
    set_privilege(privilege, false)
  end

  # Enable or disable a privilege. Note this doesn't add any privileges the
  # user doesn't already has, it just enables privileges that are disabled.
  def set_privilege(privilege, enable)
    return unless Puppet.features.root?

    with_process_token(TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY) do |token|
      tmpLuid = 0.chr * 8

      # Get the LUID for specified privilege.
      unless LookupPrivilegeValue("", privilege, tmpLuid)
        raise Puppet::Util::Windows::Error.new("Failed to lookup privilege")
      end

      # DWORD + [LUID + DWORD]
      tkp = [1].pack('L') + tmpLuid + [enable ? SE_PRIVILEGE_ENABLED : 0].pack('L')

      unless AdjustTokenPrivileges(token, 0, tkp, tkp.length , nil, nil)
        raise Puppet::Util::Windows::Error.new("Failed to adjust process privileges")
      end
    end
  end

  # Execute a block with the current process token
  def with_process_token(access)
    token = 0.chr * 4

    unless OpenProcessToken(GetCurrentProcess(), access, token)
      raise Puppet::Util::Windows::Error.new("Failed to open process token")
    end
    begin
      token = token.unpack('L')[0]

      yield token
    ensure
      CloseHandle(token)
    end
  end

  def get_security_descriptor(path)
    sd = nil

    with_privilege(SE_BACKUP_NAME) do
      open_file(path, READ_CONTROL) do |handle|
        owner_sid = [0].pack('L')
        group_sid = [0].pack('L')
        dacl = [0].pack('L')
        ppsd = [0].pack('L')

        rv = GetSecurityInfo(
          handle,
          SE_FILE_OBJECT,
          OWNER_SECURITY_INFORMATION | GROUP_SECURITY_INFORMATION | DACL_SECURITY_INFORMATION,
          owner_sid,
          group_sid,
          dacl,
          nil, #sacl
          ppsd) #sec desc
        raise Puppet::Util::Windows::Error.new("Failed to get security information") unless rv == ERROR_SUCCESS

        begin
          owner = sid_ptr_to_string(owner_sid.unpack('L')[0])
          group = sid_ptr_to_string(group_sid.unpack('L')[0])

          control = FFI::MemoryPointer.new(:uint16, 1)
          revision = FFI::MemoryPointer.new(:uint32, 1)
          ffsd = FFI::Pointer.new(ppsd.unpack('L')[0])

          if ! API.get_security_descriptor_control(ffsd, control, revision)
            raise Puppet::Util::Windows::Error.new("Failed to get security descriptor control")
          end

          protect = (control.read_uint16 & SE_DACL_PROTECTED) == SE_DACL_PROTECTED

          dacl = parse_dacl(dacl.unpack('L')[0])
          sd = Puppet::Util::Windows::SecurityDescriptor.new(owner, group, dacl, protect)
        ensure
          LocalFree(ppsd.unpack('L')[0])
        end
      end
    end

    sd
  end

  # setting DACL requires both READ_CONTROL and WRITE_DACL access rights,
  # and their respective privileges, SE_BACKUP_NAME and SE_RESTORE_NAME.
  def set_security_descriptor(path, sd)
    # REMIND: FFI
    acl = 0.chr * 1024 # This can be increased later as neede
    unless InitializeAcl(acl, acl.size, ACL_REVISION)
      raise Puppet::Util::Windows::Error.new("Failed to initialize ACL")
    end

    raise Puppet::Util::Windows::Error.new("Invalid DACL") unless IsValidAcl(acl)

    with_privilege(SE_BACKUP_NAME) do
      with_privilege(SE_RESTORE_NAME) do
        open_file(path, READ_CONTROL | WRITE_DAC | WRITE_OWNER) do |handle|
          string_to_sid_ptr(sd.owner) do |ownersid|
            string_to_sid_ptr(sd.group) do |groupsid|
              sd.dacl.each do |ace|
                case ace.type
                when ACCESS_ALLOWED_ACE_TYPE
                  #puts "ace: allow, sid #{sid_to_name(ace.sid)}, mask 0x#{ace.mask.to_s(16)}"
                  add_access_allowed_ace(acl, ace.mask, ace.sid, ace.flags)
                when ACCESS_DENIED_ACE_TYPE
                  #puts "ace: deny, sid #{sid_to_name(ace.sid)}, mask 0x#{ace.mask.to_s(16)}"
                  add_access_denied_ace(acl, ace.mask, ace.sid)
                else
                  raise "We should never get here"
                  # TODO: this should have been a warning in an earlier commit
                end
              end

              # protected means the object does not inherit aces from its parent
              flags = OWNER_SECURITY_INFORMATION | GROUP_SECURITY_INFORMATION | DACL_SECURITY_INFORMATION
              flags |= sd.protect ? PROTECTED_DACL_SECURITY_INFORMATION : UNPROTECTED_DACL_SECURITY_INFORMATION

              rv = SetSecurityInfo(handle,
                                   SE_FILE_OBJECT,
                                   flags,
                                   ownersid,
                                   groupsid,
                                   acl,
                                   nil)
              raise Puppet::Util::Windows::Error.new("Failed to set security information") unless rv == ERROR_SUCCESS
            end
          end
        end
      end
    end
  end

  module API
    extend FFI::Library
    ffi_lib 'kernel32'
    ffi_convention :stdcall

    # typedef WORD SECURITY_DESCRIPTOR_CONTROL, *PSECURITY_DESCRIPTOR_CONTROL;
    # BOOL WINAPI GetSecurityDescriptorControl(
    #   _In_   PSECURITY_DESCRIPTOR pSecurityDescriptor,
    #   _Out_  PSECURITY_DESCRIPTOR_CONTROL pControl,
    #   _Out_  LPDWORD lpdwRevision
    # );
    ffi_lib :advapi32
    attach_function :get_security_descriptor_control, :GetSecurityDescriptorControl, [:pointer, :pointer, :pointer], :bool
  end
end
