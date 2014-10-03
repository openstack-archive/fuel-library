require 'spec_helper'

describe 'monit::process' do
  let(:title) { 'testprocess' }

  let(:params) { {
    :start_command => 'start',
    :stop_command => 'stop',
    :pidfile => 'pidfile',
  } }

  let(:facts) { { :osfamily => 'debian' } }
  let(:filename) { "/etc/monit/conf.d/#{title}" }

  describe 'configuration file debian' do

    it 'is declared' do
      should contain_file(filename)
    end

    it 'requires monit to be installed' do
      # can't very well create the configuration file when the directory that
      # should contain it doesn't exist because monit has not yet been
      # installed.
      should contain_file(filename).that_requires('Class[monit::package]')
    end

    it 'comes before the monit service' do
      should contain_file(filename).that_comes_before("Service[#{title}]")
    end

    it 'notifies the monit daemon' do
      should contain_file(filename).that_notifies("Class[monit::service]")
    end
  end

  let(:facts) { { :osfamily => 'redhat' } }
  let(:filename) { "/etc/monit.d/#{title}" }

  describe 'configuration file redhat' do

    it 'is declared' do
      should contain_file(filename)
    end

    let(:facts) { { :osfamily => 'redhat' } }
    it 'requires monit to be installed' do
      # can't very well create the configuration file when the directory that
      # should contain it doesn't exist because monit has not yet been
      # installed.
      should contain_file(filename).that_requires('Class[monit::package]')
    end

    let(:facts) { { :osfamily => 'redhat' } }
    it 'comes before the monit service' do
      should contain_file(filename).that_comes_before("Service[#{title}]")
    end

    let(:facts) { { :osfamily => 'redhat' } }
    it 'notifies the monit daemon' do
      should contain_file(filename).that_notifies("Class[monit::service]")
    end
  end


  describe 'monit service' do
    it 'is declared' do
      should contain_service(title).with_provider('monit')
    end

    it 'requires the monit daemon' do
      should contain_service(title).that_requires('Service[monit]')
    end
  end
end
