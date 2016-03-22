module Puppet::Parser::Functions
  newfunction(:is_pkg_installed,
              :type => :rvalue,
              :arity => 1,
              :doc => <<-'ENDOFDOC'
Returns if given package is installed
  ENDOFDOC
  ) do |args|
    begin
      pkg_name = args[0]
      parameters = { :name => pkg_name }
      res = Puppet::Type.type(:package).new(parameters)
      query = res.provider.query
      break false unless query.is_a? Hash
      break false unless query[:ensure]
      break false if [ :absent, :purged ].include? query[:ensure]
      true
    rescue
      false
    end
  end
end
