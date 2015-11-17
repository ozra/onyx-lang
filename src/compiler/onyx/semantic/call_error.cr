require "../../crystal/semantic/call_error"

# *TODO* figure out the best way to flag and check Onyx nodes

# class Crystal::Call
#   def check_abstract_def_error(owner, matches, defs, def_name)
#     return unless !matches || (matches.try &.empty?)
#     return unless defs.all? &.abstract

#     signature = CallSignature.new(def_name, args.map(&.type), block, named_args)
#     defs.each do |a_def|
#       context = MatchContext.new(owner, a_def.owner)
#       match = MatchesLookup.match_def(signature, DefWithMetadata.new(a_def), context)
#       next unless match

#       if a_def.owner == owner
#         owner.all_subclasses.each do |subclass|
#           submatches = subclass.lookup_matches(signature)
#           if submatches.empty?
#             raise "abstract `def #{def_full_name(a_def.owner, a_def)}` must be implemented by #{subclass}"
#           end
#         end
#         raise "abstract `def #{def_full_name(a_def.owner, a_def)}` must be implemented by #{owner}"
#       else
#         raise "abstract `def #{def_full_name(a_def.owner, a_def)}` must be implemented by #{owner}"
#       end
#     end
#   end

# end
