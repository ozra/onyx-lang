# Object is the base type of all Crystal objects.
class Object
  # Returns true if this object is equal to `other`.
  #
  # Subclasses override this method to provide class-specific meaning.
  abstract def ==(other)

  # Returns true if this object is not equal to `other`.
  #
  # By default this method is implemented as `!(self == other)`
  # so there's no need to override this unless there's a more efficient
  # way to do it.
  def !=(other)
    !(self == other)
  end

  # Shortcut to `!(self =~ other)`
  def !~(other)
    !(self =~ other)
  end

  # Case equality.
  #
  # The ~~` method is used in a `switch|branch ... case ... end` expression.
  #
  # For example, this code:
  #
  # ```
  # switch value
  #   case x
  #     -- something when x
  #   case y
  #     -- something when y
  # end
  # ```
  #
  # Is equivalent to this code:
  #
  # ```
  # if x ~~ value
  #   -- something when x
  # elif y ~~ value
  #   -- something when y
  # end
  # ```
  #
  # Object simply implements ~~` by invoking `==`, but subtypes
  # (notably Regex) can override it to provide meaningful case-equality semantics.
  def ===(other)
    self == other
  end

  # Pattern match.
  #
  # Overridden by descendants (notably Regex and String) to provide meaningful
  # pattern-match semantics.
  def =~(other)
    nil
  end

  # Generates an `Int` hash value for this object.
  #
  # This method must have the property that `a == b` implies `a.hash == b.hash`.
  #
  # The hash value is used along with `==` by the `Hash` type to determine if two objects
  # reference the same hash key.
  abstract def hash

  # Returns a string representation of this object.
  #
  # Descendants must usually **not** override this method. Instead,
  # they must override `to-s(io)`, which must append to the given
  # IO object.
  def to_s
    String.build do |io|
      to_s io
    end
  end

  # Appends a String representation of this object
  # to the given IO object.
  #
  # An object must never append itself to the io argument,
  # as this will in turn call `to-s(io)` on it.
  abstract def to_s(io : IO)

  # Returns a `String` representation of this object.
  #
  # Similar to `to-s`, but usually returns more information about
  # this object.
  #
  # Classes must usually **not** override this method. Instead,
  # they must override `inspect(io)`, which must append to the
  # given IO object.
  def inspect
    String.build do |io|
      inspect io
    end
  end

  # Appends a string representation of this object
  # to the given IO object.
  #
  # Similar to `to-s(io)`, but usually appends more information
  # about this object.
  def inspect(io : IO)
    to_s io
  end

  # Yields self to the block, and then returns self.
  #
  # The primary purpose of this method is to "tap into" a method chain,
  # in order to perform operations on intermediate results within the chain.
  #
  # ```
  # (1..10).tap(\x\ puts "original: {x.inspect}")
  #        .to-a.tap(\x\ puts "array: {x.inspect}")
  #        .select(\x\ x % 2 is 0).tap(\x\ puts "evens: {x.inspect}")
  #        .map(\x\ x*x)
  #        .tap(\x\ puts "squares: {x.inspect}")
  # ```
  def tap
    yield self
    self
  end

  # Yields self. Nil overrides this method and doesn't yield.
  #
  # This method is useful for dealing with nilable types, to safely
  # perform operations only when the value is not nil.
  #
  # ```
  # -- First program argument in downcase, or nil
  # ARGV[0]?.try &.downcase
  # ```
  #
  # There is also syntax sugar in the language for this.
  #
  #
  # ```
  # -- First program argument in downcase, or nil
  # ARGV[0]?downcase
  # ```
  # Which epands internally to the exact same code as above.
  def try
    yield self
  end

  # Returns self. Nil overrides this method and raises an exception.
  def not_nil!
    self
  end

  # Return self.
  #
  # ```
  # str = "hello"
  # str.itself.object-id == str.object-id   --> true
  # ```
  def itself
    self
  end

  # Returns a shallow copy of this object.
  #
  # As a convention, `clone` is the method used to create a deep copy of
  # an object, but this logic isn't defined generically for every type
  # because cycles could be involved, and the clone logic might not need
  # to clone everything.
  #
  # Many types in the standard library, like `Array`, `Hash`, `Set` and
  # `Deque`, and all primitive types, define `dup` and `clone`.
  abstract def dup

  # Defines getter methods for each of the given arguments.
  #
  # Note!!! This is not good practise in Onyx, instead use pragmas `'get` and
  # `'set` on properties!
  #
  # Writing:
  #
  # ```
  # type Person
  #   getter name
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   name() -> @name
  # end
  # ```
  #
  # The arguments can be string literals, symbol literals or plain names:
  #
  # ```
  # type Person
  #   getter #name, "age"
  # end
  # ```
  #
  # If a type declaration is given, an instance variable with that name
  # is declared with that type.
  #
  # ```
  # type Person
  #   getter name 'String
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   @name String
  #
  #   name() -> String
  #     @name
  #   end
  # end
  # ```
  #
  # The type declaration can also include an initial value:
  #
  # ```
  # type Person
  #   getter name 'String = "John Doe"
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   @name String = "John Doe"
  #
  #   name() -> String
  #     @name
  #   end
  # end
  # ```
  #
  # An assignment can be passed too, but in this case the type of the
  # instance variable must be easily inferrable from the initial value:
  #
  # ```
  # type Person
  #   getter name = "John Doe"
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   @name = "John Doe"
  #
  #   name() -> String
  #     @name
  #   end
  # end
  # ```
  #
  # If a block is given to the macro, a getter is generated
  # with an instance variable that is lazily initialized with
  # the block's contents:
  #
  # ```
  # type Person
  #   getter birth-date, \\ Time.now
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   birth-date() ->
  #     @birth-date ||= Time.now
  #   end
  # end
  # ```
  macro getter(*names, &block)
    {% if block %}
      {% if names.size != 1 %}
        {{ raise "only one argument can be passed to `getter` with a block" }}
      {% end %}

      {% name = names[0] %}

      {% if name.is_a?(TypeDeclaration) %}
        @{{name.var.id}} : {{name.type}}?

        def {{name.var.id}}
          @{{name.var.id}} ||= {{yield}}
        end
      {% else %}
        def {{name.id}}
          @{{name.id}} ||= {{yield}}
        end
      {% end %}
    {% else %}
      {% for name in names %}
        {% if name.is_a?(TypeDeclaration) %}
          @{{name}}

          def {{name.var.id}} : {{name.type}}
            @{{name.var.id}}
          end
        {% elsif name.is_a?(Assign) %}
          @{{name}}

          def {{name.target.id}}
            @{{name.target.id}}
          end
        {% else %}
          def {{name.id}}
            @{{name.id}}
          end
        {% end %}
      {% end %}
    {% end %}
  end

  # Defines raise-on-nil and nilable getter methods for each of the given arguments.
  #
  # Writing:
  #
  # ```
  # type Person
  #   getter! name
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   name?() -> @name
  #   name() -> @name.not-nil!
  # end
  # ```
  #
  # The arguments can be string literals, symbol literals or plain names:
  #
  # ```
  # type Person
  #   getter! #name, "age"
  # end
  # ```
  #
  # If a type declaration is given, an instance variable with that name
  # is declared with that type, as nilable.
  #
  # ```
  # type Person
  #   getter! name 'String
  # end
  # ```
  #
  # is the same as writing:
  #
  # ```
  # type Person
  #   @name String?
  #
  #   name?() -> @name
  #   name() -> @name.not-nil!
  # end
  # ```
  macro getter!(*names)
    {% for name in names %}
      {% if name.is_a?(TypeDeclaration) %}
        @{{name}}?
        {% name = name.var %}
      {% end %}

      def {{name.id}}?
        @{{name.id}}
      end

      def {{name.id}}
        @{{name.id}}.not_nil!
      end
    {% end %}
  end

  # Defines query getter methods for each of the given arguments.
  #
  # Writing:
  #
  # ```
  # type Person
  #   getter? happy
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   happy?() -> @happy
  # end
  # ```
  #
  # The arguments can be string literals, symbol literals or plain names:
  #
  # ```
  # type Person
  #   getter? #happy, "famous"
  # end
  # ```
  #
  # If a type declaration is given, an instance variable with that name
  # is declared with that type.
  #
  # ```
  # type Person
  #   getter? happy 'Bool
  # end
  # ```
  #
  # is the same as writing:
  #
  # ```
  # type Person
  #   @happy Bool
  #
  #   happy?() -> Bool
  #     @happy
  #   end
  # end
  # ```
  #
  # The type declaration can also include an initial value:
  #
  # ```
  # type Person
  #   getter? happy 'Bool = true
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   @happy Bool = true
  #
  #   happy?() -> Bool
  #     @happy
  #   end
  # end
  # ```
  #
  # An assignment can be passed too, but in this case the type of the
  # instance variable must be easily inferrable from the initial value:
  #
  # ```
  # type Person
  #   getter? happy = true
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   @happy = true
  #
  #   happy?() -> @happy
  # end
  # ```
  macro getter?(*names)
    {% for name in names %}
      {% if name.is_a?(TypeDeclaration) %}
        @{{name}}

        def {{name.var.id}}? : {{name.type}}
          @{{name.var.id}}
        end
      {% elsif name.is_a?(Assign) %}
        @{{name}}

        def {{name.target.id}}?
          @{{name.target.id}}
        end
      {% else %}
        def {{name.id}}?
          @{{name.id}}
        end
      {% end %}
    {% end %}
  end

  # Defines setter methods for each of the given arguments.
  #
  # Writing:
  #
  # ```
  # type Person
  #   setter name
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   name=(@name) ->
  # end
  # ```
  #
  # The arguments can be string literals, symbol literals or plain names:
  #
  # ```
  # type Person
  #   setter #name, "age"
  # end
  # ```
  #
  # If a type declaration is given, an instance variable with that name
  # is declared with that type.
  #
  # ```
  # type Person
  #   setter name 'String
  # end
  # ```
  #
  # is the same as writing:
  #
  # ```
  # type Person
  #   @name String
  #
  #   name=(@name String) ->
  # end
  # ```
  #
  # The type declaration can also include an initial value:
  #
  # ```
  # type Person
  #   setter name 'String = "John Doe"
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   @name String = "John Doe"
  #
  #   name=(@name String) ->
  # end
  # ```
  #
  # An assignment can be passed too, but in this case the type of the
  # instance variable must be easily inferrable from the initial value:
  #
  # ```
  # type Person
  #   setter name = "John Doe"
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   @name = "John Doe"
  #
  #   name=(@name) ->
  # end
  # ```
  macro setter(*names)
    {% for name in names %}
      {% if name.is_a?(TypeDeclaration) %}
        @{{name}}

        def {{name.var.id}}=(@{{name.var.id}} : {{name.type}})
        end
      {% elsif name.is_a?(Assign) %}
        @{{name}}

        def {{name.target.id}}=(@{{name.target.id}})
        end
      {% else %}
        def {{name.id}}=(@{{name.id}})
        end
      {% end %}
    {% end %}
  end

  # Defines property methods for each of the given arguments.
  #
  # Writing:
  #
  # ```
  # type Person
  #   property name
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   name=(@name) ->
  #   name() -> @name
  # end
  # ```
  #
  # The arguments can be string literals, symbol literals or plain names:
  #
  # ```
  # type Person
  #   property #name, "age"
  # end
  # ```
  #
  # If a type declaration is given, an instance variable with that name
  # is declared with that type.
  #
  # ```
  # type Person
  #   property name 'String
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   @name String
  #
  #   name=(@name) ->
  #   name() -> @name
  # end
  # ```
  #
  # The type declaration can also include an initial value:
  #
  # ```
  # type Person
  #   property name 'String = "John Doe"
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   @name String = "John Doe"
  #
  #   name=(@name String) ->
  #   name() -> @name
  # end
  # ```
  #
  # An assignment can be passed too, but in this case the type of the
  # instance variable must be easily inferrable from the initial value:
  #
  # ```
  # type Person
  #   property name = "John Doe"
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   @name = "John Doe"
  #
  #   name=(@name String) ->
  #   name() -> @name
  # end
  # ```
  #
  # If a block is given to the macro, a property is generated
  # with an instance variable that is lazily initialized with
  # the block's contents:
  #
  # ```
  # type Person
  #   property birth-date, \\ Time.now
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   birth-date() -> @birth-date ||= Time.now
  #   birth-date=(@birth-date) ->
  # end
  # ```
  macro property(*names, &block)
    {% if block %}
      {% if names.size != 1 %}
        {{ raise "only one argument can be passed to `property` with a block" }}
      {% end %}

      {% name = names[0] %}

      setter {{name}}

      {% if name.is_a?(TypeDeclaration) %}
        @{{name.var.id}} : {{name.type}}?

        def {{name.var.id}}
          @{{name.var.id}} ||= {{yield}}
        end
      {% else %}
        def {{name.id}}
          @{{name.id}} ||= {{yield}}
        end
      {% end %}
    {% else %}
      {% for name in names %}
        {% if name.is_a?(TypeDeclaration) %}
          @{{name}}

          def {{name.var.id}} : {{name.type}}
            @{{name.var.id}}
          end

          def {{name.var.id}}=(@{{name.var.id}} : {{name.type}})
          end
        {% elsif name.is_a?(Assign) %}
          @{{name}}

          def {{name.target.id}}
            @{{name.target.id}}
          end

          def {{name.target.id}}=(@{{name.target.id}})
          end
        {% else %}
          def {{name.id}}
            @{{name.id}}
          end

          def {{name.id}}=(@{{name.id}})
          end
        {% end %}
      {% end %}
    {% end %}
  end

  # Defines raise-on-nil property methods for each of the given arguments.
  #
  # Writing:
  #
  # ```
  # type Person
  #   property! name
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   name=(@name) ->
  #
  #   name?() -> @name
  #
  #   name() -> @name.not-nil!
  # end
  # ```
  #
  # The arguments can be string literals, symbol literals or plain names:
  #
  # ```
  # type Person
  #   property! #name, "age"
  # end
  # ```
  #
  # If a type declaration is given, an instance variable with that name
  # is declared with that type, as nilable.
  #
  # ```
  # type Person
  #   property! name 'String
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   @name String?
  #
  #   name=(@name) ->
  #
  #   name?() -> @name
  #
  #   name() -> @name.not-nil!
  # end
  # ```
  macro property!(*names)
    getter! {{*names}}

    {% for name in names %}
      {% if name.is_a?(TypeDeclaration) %}
        def {{name.var.id}}=(@{{name.var.id}} : {{name.type}})
        end
      {% else %}
        def {{name.id}}=(@{{name.id}})
        end
      {% end %}
    {% end %}
  end

  # Defines query property methods for each of the given arguments.
  #
  # Writing:
  #
  # ```
  # type Person
  #   property? happy
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   happy=(@happy) ->
  #
  #   happy?() -> @happy
  # end
  # ```
  #
  # The arguments can be string literals, symbol literals or plain names:
  #
  # ```
  # type Person
  #   property? #happy, "famous"
  # end
  # ```
  #
  # If a type declaration is given, an instance variable with that name
  # is declared with that type.
  #
  # ```
  # type Person
  #   property? happy 'Bool
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   @happy Bool
  #
  #   happy=(@happy) ->
  #
  #   happy?() -> @happy
  #
  #   happy() -> @happy.not-nil!
  # end
  # ```
  #
  # The type declaration can also include an initial value:
  #
  # ```
  # type Person
  #   property? happy 'Bool = true
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   @happy 'Bool = true
  #
  #   happy=(@happy 'Bool) ->
  #
  #   happy?() -> Bool
  #     @happy
  # end
  # ```
  #
  # An assignment can be passed too, but in this case the type of the
  # instance variable must be easily inferrable from the initial value:
  #
  # ```
  # type Person
  #   property? happy = true
  # end
  # ```
  #
  # Is the same as writing:
  #
  # ```
  # type Person
  #   @happy = true
  #
  #   happy=(@happy) ->
  #   end
  #
  #   def happy?
  #     @happy
  #   end
  # end
  # ```
  macro property?(*names)
    {% for name in names %}
      {% if name.is_a?(TypeDeclaration) %}
        @{{name}}

        def {{name.var.id}}? : {{name.type}}
          @{{name.var.id}}
        end

        def {{name.var.id}}=(@{{name.var.id}} : {{name.type}})
        end
      {% elsif name.is_a?(Assign) %}
        @{{name}}

        def {{name.target.id}}?
          @{{name.target.id}}
        end

        def {{name.target.id}}=(@{{name.target.id}})
        end
      {% else %}
        def {{name.id}}?
          @{{name.id}}
        end

        def {{name.id}}=(@{{name.id}})
        end
      {% end %}
    {% end %}
  end

  # Delegate *methods* to *to*.
  #
  # Note that due to current language limitations this is only useful
  # when no fragments in parameters are involved.
  #
  # ```
  # type StringWrapper
  #   init(@string String) ->
  #
  #   delegate downcase, to: @string
  #   delegate gsub, to: @string
  #   delegate empty?, capitalize, to: @string
  # end
  #
  # wrapper = StringWrapper "HELLO"
  # wrapper.downcase           --> "hello"
  # wrapper.gsub(/E/, "A")     --> "HALLO"
  # wrapper.empty?             --> false
  # wrapper.capitalize         --> "Hello"
  # ```
  macro delegate(*methods, to object)
    {% for method in methods %}
      def {{method.id}}(*args, **options)
        {{object.id}}.{{method.id}}(*args, **options)
      end

      def {{method.id}}(*args, **options)
        {{object.id}}.{{method.id}}(*args, **options) do |*yield_args|
          yield *yield_args
        end
      end
    {% end %}
  end

  # Defines a `hash` method computed from the given fields.
  #
  # ```
  # type Person
  #   init(@name, @age) ->
  #
  #   -- Define a hash method based on @name and @age
  #   def-hash @name, @age
  # end
  # ```
  macro def_hash(*fields)
    def hash
      {% if fields.size == 1 %}
        {{fields[0]}}.hash
      {% else %}
        hash = 0
        {% for field in fields %}
          hash = 31 * hash + {{field}}.hash
        {% end %}
        hash
      {% end %}
    end
  end

  # Defines an `==` method by comparing the given fields.
  #
  # The generated `==` method has a self restriction.
  #
  # ```
  # type Person
  #   init(@name, @age) ->
  #
  #   -- Define a `==` method that compares @name and @age
  #   def-equals @name, @age
  # end
  # ```
  macro def_equals(*fields)
    def ==(other : self)
      {% for field in fields %}
        return false unless {{field.id}} == other.{{field.id}}
      {% end %}
      true
    end
  end

  # Defines `hash` and `==` method from the given fields.
  #
  # The generated `==` method has a self restriction.
  #
  # ```
  # type Person
  #   init(@name, @age) ->
  #
  #   -- Define a hash method based on @name and @age
  #   -- Define a `==` method that compares @name and @age
  #   def-equals-and-hash @name, @age
  # end
  # ```
  macro def_equals_and_hash(*fields)
    def_equals {{*fields}}
    def_hash {{*fields}}
  end

  # Forwards missing methods to delegate.
  #
  # ```
  # type StringWrapper
  #   init(@string) ->
  #
  #   forward-missing-to @string
  # end
  #
  # wrapper = StringWrapper "HELLO"
  # wrapper.downcase           --> "hello"
  # wrapper.gsub(/E/, "A")     --> "HALLO"
  # ```
  macro forward_missing_to(delegate)
    macro method_missing(call)
      {{delegate}}.\{{call}}
    end
  end

  # Defines a `clone` method that returns a copy of this
  # object with all instance variables cloned (`clone` is
  # in turn invoked on them).
  macro def_clone
    # Returns a copy of `self` with all instance variables cloned.
    def clone
      clone = \{{@type}}.allocate
      clone.initialize_copy(self)
      clone
    end

    protected def initialize_copy(other)
      \{% for ivar in @type.instance_vars %}
        @\{{ivar.id}} = other.@\{{ivar.id}}.clone
      \{% end %}
    end
  end
end
