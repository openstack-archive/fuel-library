module Puppet::Parser::Functions
  newfunctions(:create_cred_files, :type => :rvalue, :arity => 2,
:doc => <<-EOS
Create credentials files
EOS
  ) do |args|
    raise(Puppet::ParseError, 'Wrong number of arguments.') if args.size != 2
    raise(Puppet::ParseError, 'Wrong cred_users. Should  be non-empty Hash.' if !args[0].is_a?(Hash)
    raise(Puppet::ParseError, 'Wrong common_cred_params. Should  be non-empty Hash.' if !args[1].is_a?(Hash)

    cred_users, common_cred_params = args
    cres_users.keys().each do |home_dir|
      comon_cred_params.update({"owner" => cred_users[home_dir],
                                "group" => cred_users[home_dir]})
      parameters = {
        home_dir => common_cred_params
      }
    end
    function_create_resources(['osnailyfacter::credentials_file', parameters])
    end
end
