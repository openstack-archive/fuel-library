require 'puppet'
require 'puppet/type/glance_swift_config'

describe 'Puppet::Type.type(:glance_swift_config)' do
  before :each do
    Puppet::Type.rmtype(:glance_swift_config)
    Facter.fact(:osfamily).stubs(:value).returns(platform_params[:osfamily])
    @glance_swift_config = Puppet::Type.type(:glance_swift_config).new(:name => 'DEFAULT/foo', :value => 'bar')
  end

  shared_examples_for 'glance_swift_config' do
    it 'should autorequire the package that install the file' do
      catalog = Puppet::Resource::Catalog.new
      package = Puppet::Type.type(:package).new(:name => platform_params[:package_name])
      catalog.add_resource package, @glance_swift_config
      dependency = @glance_swift_config.autorequire
      expect(dependency.size).to eq(1)
      expect(dependency[0].target).to eq(@glance_swift_config)
      expect(dependency[0].source).to eq(package)
    end
  end

  context 'on Debian platforms' do
    let :platform_params do
      { :package_name => 'glance-api',
        :osfamily     => 'Debian' }
    end

    it_behaves_like 'glance_swift_config'
  end

  context 'on RedHat platforms' do
    let :platform_params do
      { :package_name => 'openstack-glance',
        :osfamily     => 'RedHat'}
    end

    it_behaves_like 'glance_swift_config'
  end

end
