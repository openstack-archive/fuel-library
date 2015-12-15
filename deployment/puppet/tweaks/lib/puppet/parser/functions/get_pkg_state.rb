module Puppet::Parser::Functions
  newfunction(:get_pkg_state,
              :type => :rvalue,
              :arity => 1,
              :doc => <<-'ENDOFDOC'
Returns status of given package resource.
  ENDOFDOC
  ) do |args|
    pkgname = args[0]

    parameters = { :name => pkgname }
    res = Puppet::Type.type(:package).new(parameters)
    return res.provider.query[:status]
  end
end
