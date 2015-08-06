require 'spec_helper'

describe PuppetSyntax::Templates do
  let(:subject) { PuppetSyntax::Templates.new }

  it 'should expect an array of files' do
    expect { subject.check(nil) }.to raise_error(/Expected an array of files/)
  end

  it 'should return nothing from a valid file' do
    files = fixture_templates('pass.erb')
    res = subject.check(files)

    expect(res).to match([])
  end

  it 'should ignore NameErrors from unbound variables' do
    files = fixture_templates('pass_unbound_var.erb')
    res = subject.check(files)

    expect(res).to match([])
  end

  it 'should catch SyntaxError' do
    files = fixture_templates('fail_error.erb')
    res = subject.check(files)

    expect(res.size).to eq(1)
    expect(res[0]).to match(/2: syntax error, unexpected/)
  end

  it 'should catch Ruby warnings' do
    files = fixture_templates('fail_warning.erb')
    res = subject.check(files)

    expect(res.size).to eq(1)
    expect(res[0]).to match(/2: warning: found = in conditional/)
  end

  it 'should read more than one valid file' do
    files = fixture_templates(['pass.erb', 'pass_unbound_var.erb'])
    res = subject.check(files)

    expect(res).to match([])
  end

  it 'should continue after finding an error in the first file' do
    files = fixture_templates(['fail_error.erb', 'fail_warning.erb'])
    res = subject.check(files)

    expect(res.size).to eq(2)
    expect(res[0]).to match(/2: syntax error, unexpected/)
    expect(res[1]).to match(/2: warning: found = in conditional/)
  end

  it 'should ignore a TypeError' do
    files = fixture_templates('typeerror_shouldwin.erb')
    res = subject.check(files)

    expect(res).to match([])
  end
end
