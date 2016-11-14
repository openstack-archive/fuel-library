module Puppet::Parser::Functions
  newfunction(:get_cred_files_hash, :type => :rvalue, :arity => 2,
:doc => <<-EOS
Build hash for credentials files creation
EOS
  ) do |args|
      raise(Puppet::ParseError, 'Wrong cred_users. Should be a Hash.') unless args[0].is_a?(Hash)
      raise(Puppet::ParseError, 'Wrong common_cred_params. Should be a Hash.') unless args[1].is_a?(Hash)

      cred_users, common_cred_params = args

      cred_users.inject({}) do |result, el|
        home_dir, owner = el.first, el.last
        result[home_dir] = common_cred_params.dup.update({'owner' => owner, 'group' => owner})
        result
      end
    end
end
