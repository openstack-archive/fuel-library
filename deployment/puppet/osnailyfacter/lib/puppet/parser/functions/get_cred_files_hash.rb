module Puppet::Parser::Functions
  newfunction(:get_cred_files_hash, :type => :rvalue, :arity => 3,
:doc => <<-EOS
Build hash for credentials files creation
EOS
  ) do |args|
      raise(Puppet::ParseError, 'Wrong cred_users. Should be a Hash.') unless args[0].is_a?(Hash)
      raise(Puppet::ParseError, 'Wrong common_cred_params. Should be a Hash.') unless args[1].is_a?(Hash)
      raise(Puppet::ParseError, 'Wrong users. Should be a Hash.') unless args[2].is_a?(Hash)

      cred_users, common_cred_params, users = args

      cred_users.inject({}) do |result, el|
        home_dir, owner = el.first, el.last
        if users.has_key?(owner)
          result[home_dir] = common_cred_params.dup.update({'owner' => owner, 'group' => owner, 'require' => 'User[#{users[owner}]'})
        else
          result[home_dir] = common_cred_params.dup.update({'owner' => owner, 'group' => owner})
        end
        result
      end
    end
end
