require 'spec_helper'
manifest = 'hiera.pp'

describe manifest do
  let :facts do
    Noop.facts
  end

  before :all do
    Noop.set_manifest manifest
  end

  it { should compile }

end
