require 'spec_helper'

describe 'nova::db::postgresql' do
  let :required_params do
    { :password => "qwerty" }
  end

  context 'on a RedHat osfamily' do
    let :facts do
      {
        :postgres_default_version => '8.4',
        :osfamily => 'RedHat'
      }
    end

    context 'with only required parameters' do
      let :params do
        required_params
      end

      it { should contain_postgresql__db('nova').with(
        :user        => 'nova',
        :password    => 'qwerty'
      )}
    end

  end

  context 'on a Debian osfamily' do
    let :facts do
      {
        :postgres_default_version => '8.4',
        :osfamily => 'Debian'
      }
    end

    context 'with only required parameters' do
      let :params do
        required_params
      end

      it { should contain_postgresql__db('nova').with(
        :user        => 'nova',
        :password    => 'qwerty'
      )}
    end

  end

end
