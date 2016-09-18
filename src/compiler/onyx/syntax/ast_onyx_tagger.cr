
# *TODO* *FIXME* crashable code:
ifdef enable_to_deliberately_crash_and_find_the_reason
  class Crystal::ASTNode
    def tag_onyx(val = true, visited = [] of ASTNode) : Nil
      @is_onyx = val

      {% for ivar, i in @type.instance_vars %}
        _{{ivar}} = @{{ivar}}
        if _{{ivar}}.is_a?(ASTNode)
          if !visited.includes? _{{ivar}}
            visited << _{{ivar}}
            _{{ivar}}.tag_onyx val, visited
            visited.pop
          end
        elsif _{{ivar}}.is_a?(Array)
          _{{ivar}}.each do |item|
            if item.is_a?(ASTNode)
              if !visited.includes? item
                visited << item
                item.tag_onyx(val, visited)
                visited.pop
              end
            end
          end
        end
      {% end %}
      nil
    end
  end

else
  class Array
    def tag_onyx(val : Bool = true, visited : Array(Crystal::ASTNode) = [] of Crystal::ASTNode) : Nil
      each do |item|
        if item.is_a?(Crystal::ASTNode)
          if !visited.includes? item
            visited << item
            item.tag_onyx(val, visited)
            visited.pop
          end
        end
      end
    end
  end

  class Crystal::ASTNode
    def tag_onyx(val : Bool = true, visited : Array(ASTNode) = [] of ASTNode) : Nil
      @is_onyx = val

      {% for ivar, i in @type.instance_vars %}
        %ivar = @{{ivar}}
        if %ivar.is_a?(ASTNode)
          if !visited.includes? %ivar
            visited << %ivar
            %ivar.tag_onyx(val, visited)
            visited.pop
          end
        elsif %ivar.is_a?(Array)
          %ivar.tag_onyx(val, visited)
        end
      {% end %}
      nil
    end
  end
end
