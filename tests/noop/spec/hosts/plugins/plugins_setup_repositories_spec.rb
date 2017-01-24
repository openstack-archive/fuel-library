# ROLE: primary-controller
require 'spec_helper'
require 'shared-examples'
manifest = 'plugins/plugins_setup_repositories.pp'

describe manifest do
  shared_examples 'catalog' do

    plugins_params  = Noop.hiera_array 'plugins'

    let(:plugin_repo_response) do
      "Label: contrail
       Version: 5.0"
    end
    before(:each) do
    if plugins_params
        plugins_params.each do |plugin|
          if plugin['repositories']
            plugin['repositories'].each do
              |repo| stub_request(:get, "#{repo['uri']}#{repo['suite']}/Release").to_return(:status => 200, :body => plugin_repo_response, :headers =>{})
            end
          end
        Thread.stubs(:abort_on_exception=)
        end
      end
    end

  it 'plugin repositories should be configured' do
    if !plugins_params.empty?
      should contain_apt__pin('contrail-5.0.0').with(
        'priority' => 1100
      )
      should contain_apt__source('contrail-5.0.0').with(
        'allow_unsigned' => true
      )
    end
  end
  end
  test_ubuntu manifest
end
