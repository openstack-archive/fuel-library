require File.expand_path('../../spec_helper', __FILE__)

describe command('mysql --user=myuser --password=mypassword --host=localhost -e "show grants"') do
  it { should return_exit_status 0 }
  it { should return_stdout /GRANT SELECT, RELOAD, LOCK TABLES ON *.* TO 'myuser'@'localhost'/ }
end

describe file('/usr/local/sbin/mysqlbackup.sh') do
  it { should be_file }
  it { should be_mode 700 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
end

describe file('/tmp/backups') do
  it { should be_directory }
  it { should be_mode 700 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
end

describe cron do
  it { should have_entry('5 23 * * * /usr/local/sbin/mysqlbackup.sh').with_user('root') }
end
