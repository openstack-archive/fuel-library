require File.expand_path('../../spec_helper', __FILE__)

$mysql_java_package = case attr[:osfamily]
  when 'Debian' then 'libmysql-java'
  when 'RedHat' then 'mysql-connector-java'
  else 'mysql-connector-java'
end

describe package($mysql_java_package) do
  it { should be_installed }
end
