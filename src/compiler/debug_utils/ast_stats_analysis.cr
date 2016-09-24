require "../crystal/syntax/visitor"
require "./debug_statistics.cr"

class DbgASTNodeCounter < Crystal::Visitor
  getter node_count = 0
  getter bind_deps_total = 0
  getter bind_observers_total = 0

  def initialize(@log_each = false)
  end

  def visit(node)
    @node_count += 1
    @bind_deps_total += node.dependencies?.try(&.size) || 0
    @bind_observers_total += node.observers.try(&.size) || 0
    _dbg_will do
      _dbg "#{node.class} : `#{node.to_s}`" if @log_each
    end
    true
  end

  # Node:invite(vis) ->, Node:items_invite(vis) or subs_invite or kids or children_invite

  def visit(node : Crystal::Require) # I don't think Req implements "invite" / "accept"
    @node_count += 1
    @bind_deps_total += node.dependencies?.try(&.size) || 0
    @bind_observers_total += node.observers.try(&.size) || 0
    _dbg_will do
      _dbg "REQUIRE: #{node.class} : `#{node.to_s}`" if @log_each
    end

    if exp = node.expanded
      exp.accept self
    end
    true
  end

end

