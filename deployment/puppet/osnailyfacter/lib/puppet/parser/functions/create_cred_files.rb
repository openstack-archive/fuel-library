module Puppet::Parser::Functions
  newfunction(:create_cred_files, :type => :rvalue, :arity => 2,
:doc => <<-EOS
Create credentials files
EOS
  ) do |args|
      raise(Puppet::ParseError, 'Wrong cred_users. Should be a Hash.') unless args[0].is_a?(Hash)
      raise(Puppet::ParseError, 'Wrong common_cred_params. Should be a Hash.') unless args[1].is_a?(Hash)

      cred_users, common_cred_params = args
      parameters = {}
      cres_users.each_pair do |home_dir, owner|
        comon_cred_params.update({"owner" => owner,
                                  "group" => owner})
        parameters.update({
          home_dir => common_cred_params
        })
      end
    function_create_resources(['osnailyfacter::credentials_file', parameters])
    end
end
