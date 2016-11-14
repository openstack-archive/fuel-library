module Puppet::Parser::Functions
  newfunction(:get_cred_files_hash, :type => :rvalue, :arity => 2,
:doc => <<-EOS
Build hash for credentials files creation
EOS
  ) do |args|
      raise(Puppet::ParseError, 'Wrong cred_users. Should be a Hash.') unless args[0].is_a?(Hash)
      raise(Puppet::ParseError, 'Wrong common_cred_params. Should be a Hash.') unless args[1].is_a?(Hash)

      cred_users, common_cred_params = args
      resources_hash = {}
      cred_users.each_pair do |home_dir, owner|
        resources_hash[home_dir] = common_cred_params.clone.update({"owner" => owner,
                                                                    "group" => owner})
      end
      resources_hash
    end
end
