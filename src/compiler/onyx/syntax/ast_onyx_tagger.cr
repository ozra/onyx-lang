module Crystal

abstract class ASTNode
   def tag_onyx(val = true, visited = [] of ASTNode) : Nil
      ind = (" " * visited.size)
      puts "#{ind}tag_onyx(#{val}, #{visited.size})"

      # return if self.is_a? Arg

      @is_onyx = val
      puts "#{ind}did set"
      {% for ivar, i in @type.instance_vars %}
         puts "#{ind}{{ivar}}:"

         _{{ivar}} = @{{ivar}}
         if _{{ivar}}.is_a?(ASTNode)
            puts "#{ind}.. is ASTNode"
            if !visited.includes? _{{ivar}}
               puts "#{ind}.. not visited"
               visited << _{{ivar}}
               _{{ivar}}.tag_onyx val, visited
               visited.pop
            end
         elsif _{{ivar}}.is_a?(Array)
            puts "#{ind}.. is Array"
            _{{ivar}}.each do |item|
               if item.is_a?(ASTNode)
                  puts "#{ind}.. item is ASTNode"
                  if !visited.includes? item
                     puts "#{ind}.. item not visited"
                     visited << item
                     item.tag_onyx(val, visited)
                     visited.pop
                  end
               end
            end
         end
      {% end %}
      puts "#{ind}."
      nil
   end
end

end
