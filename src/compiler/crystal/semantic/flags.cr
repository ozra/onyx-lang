class Crystal::Program
  @flags : Set(String)?

  # Returns the flags for this program. By default these
  # are computed from the target triple (for example x86_64,
  # darwin, linux, etc.), but can be overwritten with `flags=`
  # and also added with the `-D` command line argument.
  #
  # See `Compiler#flags`.
  def flags
    @flags ||= parse_flags(target_machine.triple.split('-'))
  end

  # Overrides the default flags with the given ones.
  def flags=(flags : String)
    @flags = parse_flags(flags.split)
  end

  # Returns `true` if *name* is in the program's flags.
  def has_flag?(name : String)
    flags.includes?(name)
  end

  private def parse_flags(flags_name)
    set = flags_name.map(&.downcase).to_set
    set.add "darwin" if set.any?(&.starts_with?("macosx"))
    set.add "freebsd" if set.any?(&.starts_with?("freebsd"))
    set.add "i686" if set.any? { |flag| %w(i586 i486 i386).includes?(flag) }

    # *TODO* *TEMP* Onyx debug help
    # {% if flag?(:typicide) %}
    ifdef disable_ox_typarchy
      set.add "disable_ox_typarchy"
    end

    ifdef disable_ox_libspicing
      set.add "disable_ox_libspicing"
    end
    # {% end %}
    set
  end
end
