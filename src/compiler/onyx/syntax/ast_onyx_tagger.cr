module Crystal

abstract class ASTNode
   def tag_onyx(val = true, visited = [] of ASTNode) : Nil
      ind = (" " * visited.size)
      puts "#{ind}tag_onyx(#{val}, #{visited.size})"
      puts "#{ind}current = #{@is_onyx.class}"
      # return if self.is_a? Arg

      @is_onyx = val
      puts "#{ind}did set"

      {% for ivar, i in @type.instance_vars %}
         # puts "#{ind}{{ivar}}:"

         _{{ivar}} = @{{ivar}}
         if _{{ivar}}.is_a?(ASTNode)
            puts "#{ind}{{ivar}} is #{_{{ivar}}.class}"
            if !visited.includes? _{{ivar}}
               visited << _{{ivar}}
               _{{ivar}}.tag_onyx val, visited
               visited.pop
            else
               puts "#{ind}.. visited!"
            end
         elsif _{{ivar}}.is_a?(Array)
            # puts "#{ind}.. is Array"
            _{{ivar}}.each do |item|
               if item.is_a?(ASTNode)
                  puts "#{ind}{{ivar}}[...] is #{item.class}"
                  if !visited.includes? item
                     visited << item
                     item.tag_onyx(val, visited)
                     visited.pop
                  else
                     puts "#{ind}.. item visited"
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
