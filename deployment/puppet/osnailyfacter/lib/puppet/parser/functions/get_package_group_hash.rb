module Puppet::Parser::Functions
  newfunction(:get_package_group_hash, :arity => -2, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
    Return a hash with package names as keys and {ensure => "version of a package"} as values.
    The keys of input hash contain regular expressions which are used to match a list of installed packages.
    For example:
      Input:  {"^.*apache2-[b,d].*$" => latest}
      Output: {
                apache2-bin         => {ensure => latest},
                apache2-data        => {ensure => latest}, }
    ENDHEREDOC

    h = Hash.new()
    p_list = lookupvar('pkglist').split("\n")

    args[0].each {|key,value|
      next if !key.ascii_only?
      p_list.select{ |pkg| pkg[/#{key}/] }.each {|elem| h[elem] = value}
    }

    return h
  end
end
