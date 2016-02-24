Puppet::Type.newtype(:cgclassify) do
  @doc = 'Move running task(s) to given cgroups'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the service to manage.'
  end

  newproperty(:cgroup, :array_matching => :all) do
    desc 'Defines the control group where the task will be moved'
    newvalues(/^\S+:\/\S*$/)

    def insync?(is)
      is.sort == should.sort
    end
  end

  newparam(:sticky, :boolean => true) do
    desc 'Prevents cgred from reassigning child processes'
    newvalues(:true, :false)

    munge do |value|
      value ? '--sticky' : '--cancel-sticky'
    end
  end

end
