Puppet::Type.type(:user).provide :hpuxuseradd, :parent => :useradd do
  desc "User management for HP-UX. This provider uses the undocumented `-F`
    switch to HP-UX's special `usermod` binary to work around the fact that
    its standard `usermod` cannot make changes while the user is logged in."

  defaultfor :operatingsystem => "hp-ux"
  confine :operatingsystem => "hp-ux"

  commands :modify => "/usr/sam/lbin/usermod.sam", :delete => "/usr/sam/lbin/userdel.sam", :add => "/usr/sam/lbin/useradd.sam"
  options :comment, :method => :gecos
  options :groups, :flag => "-G"
  options :home, :flag => "-d", :method => :dir

  verify :gid, "GID must be an integer" do |value|
    value.is_a? Integer
  end

  verify :groups, "Groups must be comma-separated" do |value|
    value !~ /\s/
  end

  has_features :manages_homedir, :allows_duplicates, :manages_passwords

  def deletecmd
    super.insert(1,"-F")
  end

  def modifycmd(param,value)
    super.insert(1,"-F")
  end

  def password
    # Password management routine for trusted and non-trusted systems
    #temp=""
    while ent = Etc.getpwent() do
      if ent.name == resource.name
        temp=ent.name
        break
      end
    end
    Etc.endpwent()
    if !temp
      return nil
    end

    ent = Etc.getpwnam(resource.name)
    if ent.passwd == "*"
      # Either no password or trusted password, check trusted
      file_name="/tcb/files/auth/#{resource.name.chars.first}/#{resource.name}"
      if File.file?(file_name)
        # Found the tcb user for the specific user, now get passwd
        File.open(file_name).each do |line|
          if ( line =~ /u_pwd/ )
            temp_passwd=line.split(":")[1].split("=")[1]
            ent.passwd = temp_passwd
            return ent.passwd
          end
        end
      else
        debug "No trusted computing user file #{file_name} found."
      end
    else
      return ent.passwd
    end
  end
end
