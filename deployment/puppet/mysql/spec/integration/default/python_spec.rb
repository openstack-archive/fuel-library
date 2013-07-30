require File.expand_path('../../spec_helper', __FILE__)

$mysql_python_package = case attr[:osfamily]
  when 'Debian' then 'python-mysqldb'
  when 'RedHat' then 'MySQL-python'
  else 'mysql-python'
end

describe package($mysql_python_package) do
  it { should be_installed }
end
