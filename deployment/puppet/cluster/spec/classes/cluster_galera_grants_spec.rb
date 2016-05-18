require 'spec_helper'

describe 'cluster::galera_grants' do

  shared_examples_for 'galera configuration' do

    context 'with valid parameters' do
      let :params do
        {
          :status_user     => 'user',
          :status_password => 'password',
        }
      end

      it 'should create grant with right privileges' do
        should contain_mysql_grant("user@%/*.*").with(
          :options    => [ 'GRANT' ],
          :privileges => [ 'USAGE' ]
        )
      end
    end
  end
end
