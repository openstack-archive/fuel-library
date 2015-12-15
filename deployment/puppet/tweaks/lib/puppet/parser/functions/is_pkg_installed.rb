module Puppet::Parser::Functions
  newfunction(:is_pkg_installed,
              :type => :rvalue,
              :arity => 1,
              :doc => <<-'ENDOFDOC'
Returns if given package is installed
  ENDOFDOC
  ) do |args|
    pkgname = args[0]

    parameters = { :name => pkgname }
    res = Puppet::Type.type(:package).new(parameters)

    query = res.provider.query

    return false if query.nil?
    query[:ensure].match(/[-.]|\d+|[^-.\d]+/) != 0
  end
end
