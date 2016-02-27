require "../../crystal/semantic/call"

class Crystal::Call
  def dbgx(str : String)
    ifdef !release
      if @onyx_node
        puts str + " " + @name
      end
    end
  end

  def lookup_matches_in_type(owner, arg_types, self_type, def_name, search_in_parents)
    # dbgx "lookup_matches_in_type"

    signature = CallSignature.new(def_name, arg_types, block, named_args)
    matches = check_tuple_indexer(owner, def_name, args, arg_types)
    matches ||= lookup_matches_checking_expansion(owner, signature, search_in_parents)




    # *TODO* *TEMP* - the ugly hack
    if matches.empty?
      dbgx "Matches are empty - is it init?"
      if def_name == "init"
        dbgx "yes  init!"

        def_name = "initialize"
        signature = CallSignature.new(def_name, arg_types, block, named_args)
        matches = check_tuple_indexer(owner, def_name, args, arg_types)
        matches ||= lookup_matches_checking_expansion(owner, signature, search_in_parents)
      end
    end




    if matches.empty?
      if def_name == "new" && owner.metaclass? && (owner.instance_type.class? || owner.instance_type.virtual?) && !owner.instance_type.pointer?
        new_matches = define_new owner, arg_types
        unless new_matches.empty?
          if owner.virtual_metaclass?
            matches = owner.lookup_matches(signature)
          else
            matches = new_matches
          end
        end
      elsif name == "super" && def_name == "initialize" && args.empty?
        # If the superclass has no `new` and no `initialize`, we can safely
        # define an empty initialize
        has_new = owner.metaclass.has_def_without_parents?("new")
        has_initialize = owner.has_def_without_parents?("initialize")
        unless has_new || has_initialize
          initialize_def = Def.new("initialize")
          owner.add_def initialize_def
          matches = Matches.new([Match.new(initialize_def, arg_types, MatchContext.new(owner, owner))], true)
        end
      elsif !obj && owner != mod
        mod_matches = lookup_matches_with_signature(mod, signature, search_in_parents)
        matches = mod_matches unless mod_matches.empty?
      end
    end

    if matches.empty? && owner.class? && owner.abstract && name != "super"
      matches = owner.virtual_type.lookup_matches(signature)
    end

    if matches.empty?
      defined_method_missing = owner.check_method_missing(signature)
      if defined_method_missing
        matches = owner.lookup_matches(signature)
      end
    end

    # dbgx "final matches.empty? check"

    if matches.empty?
      # For now, if the owner is a NoReturn just ignore the error (this call should be recomputed later)
      unless owner.no_return?
        # If the owner is abstract type without subclasses,
        # or if the owner is an abstract generic instance type,
        # don't give error. This is to allow small code comments without giving
        # compile errors, which will anyway appear once you add concrete
        # subclasses and instances.
        unless owner.abstract && (owner.leaf? || owner.is_a?(GenericClassInstanceType))
          raise_matches_not_found(matches.owner || owner, def_name, matches)
        end
      end
    end

    # dbgx "...passed"

    # If this call is an implicit call to self
    if !obj && !mod_matches && !owner.is_a?(Program)
      parent_visitor.check_self_closured
    end

    instance_type = owner.instance_type
    if instance_type.is_a?(VirtualType)
      attach_subclass_observer instance_type.base_type
    end

    instantiate matches, owner, self_type
  end
end
