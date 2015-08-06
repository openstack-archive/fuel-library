require 'spec_helper'

describe 'PuppetSyntax rake tasks' do
  it 'should generate FileList of manifests relative to Rakefile' do
    if RSpec::Version::STRING < '3'
      pending
    else
      skip('needs to be done')
    end
  end

  it 'should generate FileList of templates relative to Rakefile' do
    if RSpec::Version::STRING < '3'
      pending
    else
      skip('needs to be done')
    end
  end
end
