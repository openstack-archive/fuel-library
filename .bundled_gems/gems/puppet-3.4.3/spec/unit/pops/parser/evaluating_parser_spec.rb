require 'spec_helper'
require 'puppet/pops'
require 'puppet_spec/pops'

describe 'The hiera2 string evaluator' do

  include PuppetSpec::Pops

  let(:acceptor) {  Puppet::Pops::Validation::Acceptor.new() }
  let(:diag) { Puppet::Pops::Binder::Hiera2::DiagnosticProducer.new(acceptor) }
  let(:scope) { s = Puppet::Parser::Scope.new_for_test_harness(node); s }
  let(:node) { 'node.example.com' }

  def quote(x)
    Puppet::Pops::Parser::EvaluatingParser.quote(x)
  end

  def evaluator()
    Puppet::Pops::Parser::EvaluatingParser.new()
  end

  def evaluate(s)
    evaluator.evaluate(scope, quote(s))
  end

  def test(x)
    evaluator.evaluate_string(scope, quote(x)).should == x
  end

  def test_interpolate(x, y)
    scope['a'] = 'expansion'
    evaluator.evaluate_string(scope, quote(x)).should == y
  end

  context 'when evaluating' do
    it 'should produce an empty string with no change' do
      test('')
    end

    it 'should produce a normal string with no change' do
      test('A normal string')
    end

    it 'should produce a string with newlines with no change' do
      test("A\nnormal\nstring")
    end

    it 'should produce a string with escaped newlines with no change' do
      test("A\\nnormal\\nstring")
    end

    it 'should produce a string containing quotes without change' do
      test('This " should remain untouched')
    end

    it 'should produce a string containing escaped quotes without change' do
      test('This \" should remain untouched')
    end

    it 'should expand ${a} variables' do
      test_interpolate('This ${a} was expanded', 'This expansion was expanded')
    end

    it 'should expand quoted ${a} variables' do
      test_interpolate('This "${a}" was expanded', 'This "expansion" was expanded')
    end

    it 'should not expand escaped ${a}' do
      test_interpolate('This \${a} was not expanded', 'This ${a} was not expanded')
    end

    it 'should expand $a variables' do
      test_interpolate('This $a was expanded', 'This expansion was expanded')
    end

    it 'should expand quoted $a variables' do
      test_interpolate('This "$a" was expanded', 'This "expansion" was expanded')
    end

    it 'should not expand escaped $a' do
      test_interpolate('This \$a was not expanded', 'This $a was not expanded')
    end

    it 'should produce an single space from a \s' do
      test_interpolate("\\s", ' ')
    end
  end
end
