
describe 'zabbix::externals' do
  
  context 'should have params' do
    let :param do
      {
        :ensure => 'undef',
        :api    => 'undef',
      }
    end
    it {
      should contain_class('zabbix::externals')
    }
  end
  
  context 'should export zabbix api configs', :broken => true do
    it {
      # i believe @@ stuff is mostly untestable as of now
      should contain_zabbix_template('Template App Zabbix')
      should contain_zabbix_template_application('Zabbix')
    }
  end

end