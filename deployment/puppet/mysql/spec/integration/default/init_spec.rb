require File.expand_path('../../spec_helper', __FILE__)

$mysql_client_package = case attr[:osfamily]
  when 'Debian' then 'mysql-client'
  when 'RedHat' then 'MySQL-client'
  else 'mysql-client'
end

describe package($mysql_client_package) do
  it { should be_installed }
end
