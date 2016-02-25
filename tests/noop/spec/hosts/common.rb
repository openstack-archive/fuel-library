shared_examples 'compute_service_common' do 
  #Noop.puppet_scope.function_include ['nova::params']
  #nova_compute_service_name = Noop.puppet_scope.
  #lookupvar 'nova::params::compute_service_name'

  let (:nova_compute_service_name) do
    Noop.puppet_scope.function_include ['nova::params']
    Noop.puppet_scope.lookupvar 'nova::params::compute_service_name'
  end

  it 'should not start nova-compute service' do
    is_expected.not_to contain_service(nova_compute_service_name).
      with(:ensure => 'running')
  end

end

shared_examples 'common' do
  if Noop.file_name_manifest != 'astute/enable_compute.pp'
    include_examples 'compute_service_common'
  end
end

