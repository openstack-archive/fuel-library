module Puppet::Parser::Functions
  newfunction(:filter_hash, :type => :rvalue,  :doc => <<-EOS
    Map array of hashes $arg0 to an array yielding 
    an element from each hash by key $arg1
    EOS
 ) do |args|
    hash = args[0]
    field  = args[1]
    if hash.respond_to?('each')
       hash.map do |e|
          e[field]
       end
    else
      []
    end
  end
end
