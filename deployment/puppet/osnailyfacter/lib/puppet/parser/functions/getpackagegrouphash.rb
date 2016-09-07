module Puppet::Parser::Functions
  newfunction(:getpackagegrouphash, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
    Return a hash with package names as keys and {ensure => "version of a package"} as values.
    The keys of input hash contains regular expressions which are used to match a list of installed packages.
    For example:
      Input:  {"^.*apache2-[b,d].*$" => latest}
      Output: {
                apache2-bin         => {ensure => latest}, 
                apache2-data        => {ensure => latest}, }
    ENDHEREDOC

    h = Hash.new()
    args[0].each {|key,value| 
      grep_expr = "grep -Ew #{key}"
    
      case lookupvar("osfamily")
      when "Debian"
        p_list = %x`dpkg -l | grep -E "^[ a-z]{3}\s" | awk -F" " '{print $2}' | #{grep_expr}`
      when "RedHat"
        p_list = %x`rpm -qa | #{grep_expr}`
      end

      p_list.split("\n").each  {|elem| h[elem] = value unless args[1].include?(elem) }

    }
    return h
  end
end
