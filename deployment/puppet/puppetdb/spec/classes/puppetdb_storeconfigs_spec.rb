require 'spec_helper'

describe 'puppetdb::storeconfigs', :type => :class do

    context 'on Debian' do
        let (:params) do
            {
                :dbserver         => 'test.example.com',
                :dbport           => '8081',
                :puppet_confdir   => '/etc/puppet/',
                :puppet_conf      => '/etc/puppet/puppet.conf',
            }
        end

        it {
                should contain_class('puppetdb::terminus')
                should contain_ini_setting('puppetmasterstoreconfig').with(
                    :ensure  => 'present',
                    :section => 'master',
                    :setting => 'storeconfigs',
                    :path    => params[:puppet_conf],
                    :value   =>'true'
                )
                should contain_ini_setting('puppetmasterstorebackend').with(
                    :ensure  => 'present',
                    :section => 'master',
                    :setting => 'storeconfigs_backend',
                    :path    => params[:puppet_conf],
                    :value   =>'puppetdb'
                )
                should contain_ini_setting('puppetmasterstoreconfigserver').with(
                    :ensure  => 'present',
                    :section => 'master',
                    :setting => 'server',
                    :path    => params[:puppet_conf],
                    :value   => params[:dbserver]
                )
        }
    end
end
