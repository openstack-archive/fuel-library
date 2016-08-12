require 'spec_helper'

class_object = Puppet::Type.type(:update_packages)

describe class_object do
  before(:each) do
    puppet_debug_override
  end

  let(:update_resource) do
    class_object.new(
        {
            :title => 'update',
            :versions => package_versions,
            :generate_provider => :apt,
            :instances_provider => %w(apt apt_fuel rpm yum),
        }
    )
  end

  subject { update_resource }

  let(:package_type) do
    Puppet::Type.type(:package)
  end

  let(:pkg1) do
    package_type.new(
        {
            :title => 'pkg1',
            :ensure => :present,
            :provider => :apt,
        }
    )
  end

  let(:pkg2) do
    package_type.new(
        {
            :title => 'my_package',
            :ensure => :installed,
            :name => 'pkg2',
            :provider => :apt,
        }
    )
  end

  let(:pkg3) do
    package_type.new(
        {
            :title => 'pkg3',
            :ensure => :absent,
            :provider => :apt,
        }
    )
  end

  let(:pkg4) do
    package_type.new(
        {
            :title => 'pkg4',
            :ensure => :present,
            :provider => :apt,
        }
    )
  end

  let(:pkg5) do
    package_type.new(
        {
            :title => 'pkg5',
            :ensure => :present,
            :provider => :apt,
        }
    )
  end

  let(:catalog) do
    catalog = Puppet::Resource::Catalog.new
    catalog.add_resource update_resource
    catalog.add_resource pkg1
    catalog.add_resource pkg2
    catalog.add_resource pkg3
    catalog
  end

  let(:package_versions) do
    {
        'pkg1' => '1',
        'pkg2' => '2',
        'pkg5' => '5',
    }
  end

  let(:package_versions_latest) do
    {
        '*' => 'latest',
    }
  end

  let(:instances) do
    pkg1[:ensure] = :present
    pkg5[:ensure] = :present
    [pkg1, pkg5]
  end

  let(:catalog_packages_data) do
    packages = {}
    catalog.resources.each do |resource|
      next unless resource.type == :package
      packages.store resource.title, resource[:ensure]
    end
    packages
  end

  let(:run_generate_function) do
    resource = catalog.resource 'update_packages', 'update'
    fail 'Update_packages resource was not found in the catalog!' unless resource
    resource.generate.each do |resource|
      catalog.add_resource resource
    end
  end

  let(:catalog_data) do
    {
        'pkg1' => :present,
        'my_package' => :present,
        'pkg3' => :absent,
    }
  end

  it { is_expected.not_to be_nil }

  it 'can operate the catalog' do
    expect(catalog_packages_data).to eq catalog_data
  end

  context 'in the "catalog" mode' do

    context 'with a normal versions data' do
      it 'can update the packages in the catalog with the new versions' do
        run_generate_function
        catalog_data['my_package'] = '2'
        catalog_data['pkg1'] = '1'
        expect(catalog_packages_data).to eq catalog_data
      end

      it 'can use the package list to limit the packages affected' do
        update_resource[:packages] = ['pkg1']
        run_generate_function
        catalog_data['pkg1'] = '1'
        expect(catalog_packages_data).to eq catalog_data
      end
    end

    context 'with "*" in the versions data' do
      let(:package_versions) do
        package_versions_latest
      end

      it 'will update all catalog packages' do
        run_generate_function
        catalog_data['my_package'] = :latest
        catalog_data['pkg1'] = :latest
        expect(catalog_packages_data).to eq catalog_data
      end

      it 'can use the package list to limit the packages affected' do
        update_resource[:packages] = ['pkg1']
        run_generate_function
        catalog_data['pkg1'] = :latest
        expect(catalog_packages_data).to eq catalog_data
      end
    end

  end

  context 'on the "generate" mode' do
    before(:each) do
      update_resource[:mode] = :generate
    end

    context 'with a normal versions data' do
      it 'can update the packages in the catalog with the new versions and create new packages' do
        run_generate_function
        catalog_data['my_package'] = '2'
        catalog_data['pkg1'] = '1'
        catalog_data['pkg5'] = '5'
        expect(catalog_packages_data).to eq catalog_data
      end

      it 'can use the package list to limit the packages affected and created or add new packages' do
        update_resource[:packages] = %w(pkg1 pkg4)
        run_generate_function
        catalog_data['pkg1'] = '1'

        catalog_data['pkg4'] = :present
        expect(catalog_packages_data).to eq catalog_data
      end
    end

    context 'with "*" in the versions data' do
      let(:package_versions) do
        package_versions_latest
      end

      it 'will update all catalog packages' do
        run_generate_function
        catalog_data['my_package'] = :latest
        catalog_data['pkg1'] = :latest
        expect(catalog_packages_data).to eq catalog_data
      end

      it 'can use the package list to limit the packages affected' do
        update_resource[:packages] = ['pkg1']
        run_generate_function
        catalog_data['pkg1'] = :latest
        expect(catalog_packages_data).to eq catalog_data
      end
    end

  end

  context 'in the "installed" mode' do
    before(:each) do
      update_resource[:mode] = :installed
      allow(package_type).to receive(:instances).and_return(instances)
    end

    context 'with a normal versions data' do
      it 'can update the packages in the catalog with the new versions and create new packages for all the installed ones' do
        run_generate_function
        catalog_data['my_package'] = '2'
        catalog_data['pkg1'] = '1'
        catalog_data['pkg5'] = '5'
        expect(catalog_packages_data).to eq catalog_data
      end

      it 'can use the package list to limit the packages affected and created instances for all the installed packages' do
        update_resource[:packages] = %w(pkg1 pkg4)
        run_generate_function
        catalog_data['pkg1'] = '1'
        catalog_data['pkg4'] = :present
        catalog_data['pkg5'] = '5'
        expect(catalog_packages_data).to eq catalog_data
      end
    end

    context 'with "*" in the versions data' do
      let(:package_versions) do
        package_versions_latest
      end

      it 'will update all catalog packages' do
        run_generate_function
        catalog_data['my_package'] = :latest
        catalog_data['pkg1'] = :latest
        catalog_data['pkg5'] = :latest
        expect(catalog_packages_data).to eq catalog_data
      end

      it 'can use the package list to limit the packages affected' do
        update_resource[:packages] = ['pkg5']
        run_generate_function
        catalog_data['pkg5'] = :latest
        expect(catalog_packages_data).to eq catalog_data
      end
    end
  end

  context 'in the "update" mode' do
    before(:each) do
      update_resource[:mode] = :update
      allow(package_type).to receive(:instances).and_return(instances)
    end

    context 'with a normal versions data' do
      it 'can update the packages in the catalog with the new versions and create new packages for installed ones' do
        run_generate_function
        catalog_data['my_package'] = '2'
        catalog_data['pkg1'] = '1'
        catalog_data['pkg5'] = '5'
        expect(catalog_packages_data).to eq catalog_data
      end

      it 'can use the package list to limit the packages affected and created instances for the installed packages' do
        update_resource[:packages] = %w(pkg1 pkg4)
        run_generate_function
        catalog_data['pkg1'] = '1'
        expect(catalog_packages_data).to eq catalog_data
      end
    end

    context 'with "*" in the versions data' do
      let(:package_versions) do
        package_versions_latest
      end

      it 'will update all catalog packages' do
        run_generate_function
        catalog_data['my_package'] = :latest
        catalog_data['pkg1'] = :latest
        expect(catalog_packages_data).to eq catalog_data
      end

      it 'can use the package list to limit the packages affected' do
        update_resource[:packages] = ['pkg5']
        run_generate_function
        catalog_data['pkg5'] = :latest
        expect(catalog_packages_data).to eq catalog_data
      end
    end
  end

end
