require 'spec_helper'

describe 'puppetdb::terminus', :type => :class do

    context 'on Debian' do
        let (:params) do
            {
                :dbserver         => 'test.example.com',
                :dbport           => '8081',
                :puppet_confdir   => '/etc/puppet/',
            }
        end

        it {
                should contain_package('puppetdb-terminus').with(
                    :ensure     => 'present'
                )
                should contain_file("#{params[:puppet_confdir]}/routes.yaml").with(
                    :ensure     => 'file',
                    :source     => 'puppet:///modules/puppet/routes.yaml',
                    :notify     => params[:puppet_service],
                    :require    => 'Package[puppetdb-terminus]'
                )
                should contain_file("#{params[:puppet_confdir]}/puppetdb.conf").with(
                    :ensure     => 'file',
                    :notify     => params[:puppet_service],
                    :require    => "File[#{params[:puppet_confdir]}/routes.yaml]"
                )
                should contain_ini_setting('puppetterminusserver').with(
                    :ensure  => 'present',
                    :section => 'main',
                    :setting => 'server',
                    :path    => "#{params[:puppet_confdir]}/puppetdb.conf",
                    :value   => params[:dbserver]
                )
                should contain_ini_setting('puppetterminusport').with(
                    :ensure  => 'present',
                    :section => 'main',
                    :setting => 'port',
                    :path    => "#{params[:puppet_confdir]}/puppetdb.conf",
                    :value   => params[:dbport]
                )
        }
    end
end
