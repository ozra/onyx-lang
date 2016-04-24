module Crystal

abstract class ASTNode
   macro def tag_onyx(val = true, visited = [] of ASTNode) : Nil
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
                  item.tag_onyx(val, visited)
               end
            end
         end
      {% end %}
      nil
   end
end

end