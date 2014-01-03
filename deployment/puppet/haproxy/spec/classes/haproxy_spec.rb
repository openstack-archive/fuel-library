require 'spec_helper'

describe 'haproxy', :type => :class do
  let(:default_facts) do
    {
      :concat_basedir => '/dne',
      :ipaddress => '10.10.10.10'
    }
  end

  context 'on supported platforms' do
    describe 'for OS-agnostic configuration' do
      ['Debian', 'RedHat'].each do |osfamily|
        context "on #{osfamily} family operatingsystems" do
          let(:facts) do
            { :osfamily => osfamily }.merge default_facts
          end

          let(:params) do
            {'enable' => true}
          end

          it 'should install the haproxy package' do
            subject.should contain_package('haproxy').with(
              'ensure' => 'present'
            )
          end

          it 'should install the haproxy service' do
            subject.should contain_service('haproxy').with(
              'ensure'     => 'running',
              'enable'     => 'true',
              'hasrestart' => 'true',
              'hasstatus'  => 'true'
            ).that_requires('Class[haproxy::base]')
          end
        end

        context "on #{osfamily} family operatingsystems without managing the service" do
          let(:facts) do
            { :osfamily => osfamily }.merge default_facts
          end
          let(:params) do
            {
              'enable'         => true,
              'manage_service' => false,
            }
          end

          it { should contain_class('haproxy::base') }

          it 'should install the haproxy package' do
            subject.should contain_package('haproxy').with(
              'ensure' => 'present'
            )
          end

          it 'should not manage the haproxy service' do
            subject.should_not contain_service('haproxy')
          end
        end
      end
    end

    describe 'for OS-specific configuration' do
      context 'only on Debian family operatingsystems' do
        let(:facts) do
          { :osfamily => 'Debian' }.merge default_facts
        end

        it 'should manage haproxy service defaults' do
          subject.should contain_file('/etc/default/haproxy').with(
            'before'  => 'Service[haproxy]',
            'require' => 'Package[haproxy]'
          )
          verify_contents(subject, '/etc/default/haproxy', ['ENABLED=1'])
        end
      end

      context 'only on RedHat family operatingsystems' do
        let(:facts) do
          { :osfamily => 'RedHat' }.merge default_facts
        end
      end
    end
  end

  context 'on unsupported operatingsystems' do
    let(:facts) do
      { :osfamily => 'RainbowUnicorn' }.merge default_facts
    end
    it do
      expect {
        should contain_service('haproxy')
      }.to raise_error(Puppet::Error, /operating system is not supported with the haproxy module/)
    end
  end
end
