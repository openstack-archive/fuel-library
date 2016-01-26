module FuelRelationshipGraphMatchers
  class EnsureTransitiveDependency
    def initialize(before, after)
      @before = before
      @after = after
    end

    def matches?(actual_graph)
      @actual_graph = actual_graph

      @dependents = actual_graph.dependents(
        vertex_called(actual_graph, @before))
      !@dependents.find_all { |d| d.ref =~ /#{Regexp.escape(@after)}/i }.empty?
    end

    def failure_message
      binding.pry
      msg = "expected deployment graph to contain a transitional dependency between\n"
      msg << "#{@before} and #{@after} but it did not happen\n"
      msg << "#{@before} dependents are: #{@dependents.map {|dep| dep.ref}}\n"
      msg
    end

    def failure_message_when_negated
      msg = "expected deployment graph to NOT contain a transitional dependency between\n"
      msg << "#{@before} and #{@after} but it did not happen\n"
      msg << "#{@before} dependents are: #{@dependents.map {|dep| dep.ref}}\n"
      msg
    end

    private

    def vertex_called(graph, name)
      graph.vertices.find { |v| v.ref =~ /#{Regexp.escape(name)}/i }
    end
  end

  def ensure_transitive_dependency(before, after)
    EnsureTransitiveDependency.new(before, after)
  end
end
