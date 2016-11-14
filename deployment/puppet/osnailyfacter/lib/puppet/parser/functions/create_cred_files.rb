module Puppet::Parser::Functions
  newfunctions(:create_cred_files,:type => :rvalue,
:doc => <<-EOS
Create credentials files
EOS
  ) do |arguments|
    raise(Puppet::ParseError, 'No data provided!') if argument.size != 2
    
    owners = arguments[0]
    params = arguments[1]
    owners.keys().uniq.each do |home_dir|
      params["owner"]=owners[home_dir]
      params["group"]=owners[home_dir]
      parameter = {
        home_dir => params
      }
      function_create_resources(['osnailyfacter::credentials_file', params])
    end
end 
