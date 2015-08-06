require 'puppet/parser/ast/top_level_construct'

class Puppet::Parser::AST::Hostclass < Puppet::Parser::AST::TopLevelConstruct
  attr_accessor :name, :context

  def initialize(name, context = {}, &ruby_code)
    @context = context
    @name = name
    @ruby_code = ruby_code
  end

  def instantiate(modname)
    new_class = Puppet::Resource::Type.new(:hostclass, @name, @context.merge(:module_name => modname))
    new_class.ruby_code = @ruby_code if @ruby_code
    all_types = [new_class]
    if code
      code.each do |nested_ast_node|
        if nested_ast_node.respond_to? :instantiate
          all_types += nested_ast_node.instantiate(modname)
        end
      end
    end
    return all_types
  end

  def code()
    @context[:code]
  end
end
