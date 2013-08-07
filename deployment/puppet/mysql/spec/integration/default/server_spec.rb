require File.expand_path('../../spec_helper', __FILE__)

$mysql_server_package = case attr[:osfamily]
  when 'Debian' then 'mysql-server'
  when 'RedHat' then 'MySQL-server'
  else 'mysql-server'
end

$mysql_server_service = case attr[:osfamily]
  when 'Debian' then 'mysql'
  when 'RedHat' then 'mysql'
  else 'mysql'
end

describe package($mysql_server_package) do
  it { should be_installed }
end

describe service($mysql_server_service) do
  it { should be_running }
  it { should be_enabled }
end

describe file('/root/.my.cnf') do
  it { should be_file }
  it { should contain '[client]' }
  it { should contain 'user=root' }
  it { should contain 'host=localhost' }
  it { should contain 'password=password' }
end

describe command('mysql -B -e "show create database redmine_db"') do
  it { should return_exit_status 0 }
  it { should return_stdout /CHARACTER SET utf8/ }
end

describe command('mysql -B -e "show create database other_db"') do
  it { should return_exit_status 0 }
  it { should return_stdout /CHARACTER SET utf8/ }
end

describe command('mysql -B -e "show create database old_db"') do
  it { should return_exit_status 0 }
  it { should return_stdout /CHARACTER SET latin1/ }
end

describe command('mysql --user=dan --password=blah --host=localhost -e "show grants"') do
  it { should return_exit_status 0 }
  it { should return_stdout /GRANT ALL PRIVILEGES ON `other_db`.* TO 'dan'@'localhost' WITH GRANT OPTION/ }
end

describe command('mysql --user=redmine --password=redmine --host=localhost -e "show grants"') do
  it { should return_exit_status 0 }
  it { should return_stdout /GRANT ALL PRIVILEGES ON `redmine_db`.* TO 'redmine'@'localhost' WITH GRANT OPTION/ }
end

describe command('mysql -B -e "show create database test"') do
  it { should_not return_exit_status 0 }
end

describe command('mysql -e "show grants for \'\'@\'localhost\'"') do
  it { should_not return_exit_status 0 }
  it { should_not return_stdout /GRANT USAGE ON/ }
end

