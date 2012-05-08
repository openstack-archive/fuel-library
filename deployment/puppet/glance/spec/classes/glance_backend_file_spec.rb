require 'spec_helper'

describe 'glance::backend::file' do
  let :facts do
    {
      :concat_basedir => '/var/lib/puppet/concat',
      :osfamily => 'Debian'
    }
  end
  it 'should set the default store to file' do
    verify_contents(
      subject,
      '/var/lib/puppet/concat/_etc_glance_glance-api.conf/fragments/04_glance-api-backend',
      ['default_store = file']
    )
  end
  it 'should configure file backend settings' do
    verify_contents(
      subject,
      '/var/lib/puppet/concat/_etc_glance_glance-api.conf/fragments/05_glance-api-file',
      ['filesystem_store_datadir = /var/lib/glance/images/']
    )
  end
  describe 'when datadir is overridden' do
    let :params do
      {
        :filesystem_store_datadir => '/var/lib/glance/images2'
      }
    end

    it 'should configure file backend settings with specified parameter' do
      verify_contents(
        subject,
        '/var/lib/puppet/concat/_etc_glance_glance-api.conf/fragments/05_glance-api-file',
        ['filesystem_store_datadir = /var/lib/glance/images2']
      )
    end
  end
end
