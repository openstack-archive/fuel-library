shared_examples 'compute_service_common' do

  let (:nova_compute_service_name) do
    if facts[:osfamily] == 'RedHat'
      'openstack-nova-compute'
    elsif facts[:osfamily] == 'Debian'
      'nova-compute'
    else
      fail "Osfamily: #{facts[:osfamily]} is not supported!"
    end
  end


  it do
    is_expected.not_to contain_service(nova_compute_service_name).with(:ensure => 'running')
  end

end

shared_examples 'override_resources' do
  let(:configuration_override) do
    Noop.hiera_structure 'configuration'
  end

  let(:package_config) do
    configuration_override.fetch('package', {}).fetch('data', {})
  end

  it 'should create/update params with override_resources' do
    configuration_override.each do |resource, config|
      is_expected.to contain_override_resources(resource).with(:data => config.fetch('data', config))
    end
  end

  if Noop.task_spec.to_s != 'murano/murano_spec.rb'
    it 'should use "override_resources" to update the catalog' do
      ral_catalog = Noop.create_ral_catalog self
      configuration_override.each do |resource, config|
        config.fetch('data', config).each do |title, params|
          params['value'] = ['True'] if params['value'].is_a? TrueClass
          contain_resource = send("contain_#{resource}", title)
          expect(ral_catalog).to contain_resource.with(params)
        end
      end
    end
  end

end

shared_examples 'common' do
  include_examples 'compute_service_common' unless Noop.current_spec_is? 'roles/enable_compute'
  include_examples 'override_resources'
end

