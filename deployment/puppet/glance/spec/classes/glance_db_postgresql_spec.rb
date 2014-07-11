require 'spec_helper'

describe 'glance::db::postgresql' do

  let :req_params do
    {:password => 'pw'}
  end

  let :facts do
    {
      :postgres_default_version => '8.4',
      :osfamily => 'RedHat',
    }
  end

  describe 'with only required params' do
    let :params do
      req_params
    end
    it { should contain_postgresql__db('glance').with(
      :user         => 'glance',
      :password     => 'pw'
     ) }
  end

end
