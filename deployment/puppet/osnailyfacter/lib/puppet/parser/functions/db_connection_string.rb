Puppet::Parser::Functions::newfunction(:db_connection_string, :type => :rvalue, :doc =>
<<-EOS
Build a connection string based on parameters.

db_connection_string(host, user, pass, database, type='mysql', extra_params='')
  host         - (String) database host
  user         - (String) database username
  pass         - (String) database password
  database     - (String) database name
  type         - (String) database type (Default 'mysql')
  extra_params - (String) Extra connection string parameters (Default '')

Returns if no extra_params provided:
  "type://user:pass@host/name"

Returns if extra_params provided:
  "type://user:pass@host/database?extra_params"
EOS

) do |argv|

  raise(Puppet::ParserError, 'Missing required parameters') if argv.size < 4
  host, user, pass, database, type, extra_params = argv
  type ||= 'mysql'
  extra_params ||= ''

  connection_string =  "#{type}://#{user}:#{pass}@#{host}/#{database}"
  connection_string += "?#{extra_params}" unless extra_params.empty?

  connection_string
end
