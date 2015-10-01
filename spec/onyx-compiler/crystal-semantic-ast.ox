require "../syntax/ast"
require "simple-hash"

-- TODO: 100 is a pretty big number for the number of nested generic instantiations,
-- but we might want to implement an algorithm that correctly identifies this
-- infinite recursion.
#priv# fn generic-type-too-nested?(nest-level)
    nest-level > 100

begin module Crystal

self.fn check-type-allowed-in-generics(node, type, msg)
    return if type.allowed-in-generics?

    type = type.union-types.find { |t| !t.allowed-in-generics? } if type.of?(UnionType)
    node.raise "{{msg}} yet, use a more specific type"
end-type

type ASTNode
    @type  #prop#
    @dependencies  #prop#
    @freeze-type  #prop#
    @observers  #prop#
    @input-observers  #prop#

    @dirty Bool = false

    fn type()
        @type || ::raise "Bug: `{{self}}` at {{self.location}} has no type"

    fn type?()
        @type

    fn set-type(type Type)
        type = type.remove-alias-if-simple
        if !type.no-return? && (freeze-type = @freeze-type) && !freeze-type.is-restriction-of-all?(type)
            if !freeze-type.includes-type?(type.program.nil) && type.includes-type?(type.program.nil)
                -- This means that an instance variable become nil
                if self.of?(MetaInstanceVar) && (nil-reason = self.nil-reason)
                    inner = MethodTraceException(nil, [] of ASTNode, nil-reason)

            raise "type must be {{freeze-type}}, not {{type}}", inner, Crystal:FrozenTypeException
        end-if
        @type = type

    fn set-type(type Nil)
        @type = type

    fn set-type-from(type, from)
        set-type type
    rescue ex FrozenTypeException
        -- See if we can find where the mismatched type came from
        if from && !ex.inner && (freeze-type = @freeze-type) && type.of?(UnionType) && type.includes-type?(freeze-type) && type.union-types.size == 2
            other-type = type.union-types.find { |type| type != freeze-type }
            trace = from.find-owner-trace(other-type)
            ex.inner = trace

        if from && !location
            from.raise ex.message, ex.inner
        else
            ::raise ex
    end

    fn type=(type)
        return if type.nil? || @type.same?(type)

        set-type(type)
        notify-observers
        @type

    fn map-type(type)
        type

    fn bind-to(node ASTNode)
        bind(node) do |dependencies|
            dependencies.push node
            node.add-observer self
            node

    fn bind-to(nodes Arr)
        return if nodes.empty?

        bind do |dependencies|
            dependencies.concat nodes
            nodes.each &.add-observer self
            nodes.first

    fn bind(from = nil)
        dependencies = @dependencies ||= Dependencies()

        node = yield dependencies

        if dependencies.size == 1
            new-type = node.type?
        else
            new-type = Type.merge dependencies

        return if @type.same? new-type
        return unless new-type

        set-type-from(map-type(new-type), from)
        @dirty = true
        propagate

    fn unbind-all()
        @dependencies.?.each &.remove-observer(self)
        @dependencies = nil

    fn unbind-from(nodes Nil)
        -- Nothing to do

    fn unbind-from(node ASTNode)
        @dependencies.?.reject! &.same?(node)
        node.remove-observer self

    fn unbind-from(nodes Arr{ASTNode})
        for node in nodes
            unbind-from node

    fn unbind-from(nodes Dependencies)
     -- nodes.each do |node|
     --     unbind_from node
     -- end

     -- nodes.each (node) ~>
     --     unbind-from node

        for node in nodes
            unbind-from node


    fn add-observer(observer)
        observers = (@observers ||= [] of ASTNode)
        observers << observer

    fn remove-observer(observer)
        @observers.?.reject! &.same?(observer)

    fn add-input-observer(observer)
        input-observers = (@input-observers ||= [] of Call)
        input-observers << observer

    fn remove-input-observer(observer)
        @input-observers.?.reject! &.same?(observer)

    fn notify-observers()
        @observers.?.each &.update self
        @input-observers.?.each &.update-input self
        @observers.?.each &.propagate
        @input-observers.?.each &.propagate

    fn update(from)
        return if @type.same? from.type

        if dependencies.size == 1 || !@type
            new-type = from.type?
        else
            new-type = Type.merge dependencies

        return if @type.same? new-type
        return unless new-type

        set-type-from(map-type(new-type), from)
        @dirty = true

    fn propagate()
        if @dirty
            @dirty = false
            notify-observers

    fn raise(message, inner = nil, exception-type = Crystal:TypeException)
        ::raise exception-type.for-node(self, message, inner)

    fn visibility=(visibility)

    fn visibility()
        nil

    fn find-owner-trace(owner)
        owner-trace = [] of ASTNode
        node = self

        visited = Set{typeof(object-id)}()
        visited.add node.object-id
        while deps = node.dependencies?
            dependencies = deps.select { |dep| dep.type? && dep.type.includes-type?(owner) && !visited.includes?(dep.object-id) }
            if dependencies.size > 0
                node = dependencies.first
                nil-reason = node.nil-reason if node.of?(MetaInstanceVar)
                owner-trace << node if node
                visited.add node.object-id
            else
                break

        MethodTraceException(owner, owner-trace, nil-reason)
end-type

type Def
    @owner  #prop#
    @original-owner  #prop#
    @vars  #prop#
    @yield-vars  #prop#
    @raises  #prop#

    @closure = false  #prop#

    @self-closured = false  #prop#

    @previous  #prop#
    @next  #prop#
    @visibility  #prop#
    @special-vars  #get#

    @block-nest  #prop#
    @block-nest = 0

    fn macro-owner=(@macro-owner)

    fn macro-owner()
        @macro-owner || @owner

    fn add-special-var(name)
        special-vars = @special-vars ||= Set{Str}()
        special-vars << name
end-type

type PointerOf
    -- This is to detect cases like `x = pointerof(x)`, where
    -- the type keeps growing indefinitely
    @growth = 0

    fn map-type(type)
        old-type = self.type?
        new-type = type.?.program.pointer-of(type)
        if old-type && grew?(old-type, new-type)
            @growth += 1
            if @growth > 4
                raise "recursive pointerof expansion: {{old-type}}, {{new-type}}, ..."

        else
            @growth = 0

        new-type

    fn grew?(old-type, new-type)
        new-type = new-type as PointerInstanceType
        element-type = new-type.element-type
        element-type.of?(UnionType) && element-type.includes-type?(old-type)
end-type

type TypeOf
    @in-type-args = false  #prop#

    fn map-type(type)
        if @in-type-args ? type : type.metaclass

    fn update(from = nil)
        super
        propagate
end-type

type ExceptionHandler
    fn map-type(type)
        if (ensure-type = @ensure.?.type?).?.of?(NoReturnType)
            ensure-type
        else
            type
end-type

type Cast
    @upcast = false  #prop#

    fn self.apply(node ASTNode, type Type)
        cast = Cast(node, Var("cast", type))
        cast.set-type(type)
        cast

    fn update(from = nil)
        to-type = to.type

        obj-type = obj.type?

        -- If we don't know what type we are casting from, leave it as the to-type
        unless obj-type
            self.type = to-type.virtual-type
            return

        if obj-type.pointer? || to-type.pointer?
            self.type = to-type
        else
            filtered-type = obj-type.filter-by(to-type)

            -- If the filtered type didn't change it means that an
            -- upcast is being made, for example:
            --
            --     1 as Int32 | Float64
            --     Bar() as Foo -- where Bar < Foo
            if obj-type == filtered-type && 
               obj-type != to-type && 
               !to-type.of?(GenericClassType)
            => -- do -- then
                filtered-type = to-type.virtual-type
                @upcast = true
            end
            -- If we don't have a matching type, leave it as the to-type:
            -- later (in after type inference) we will check again.
            filtered-type ||= to-type.virtual-type

            self.type = filtered-type
end-type

type FunDef
    @external  #prop#
end-type

type FunLiteral
    @force-void = false  #prop#
    @expected-return-type  #prop#

    fn update(from = nil)
        return unless self.def.args.all? &.type?
        return unless self.def.type?

        types = self.def.args.map &.type
        return-type = @force-void ? self.def.type.program.void : self.def.type

        expected-return-type = @expected-return-type
        if expected-return-type && !expected-return-type.void? && expected-return-type != return-type
            raise "expected new to return {{expected-return-type}}, not {{return-type}}"

        types << return-type

        self.type = self.def.type.program.fun-of(types)
    end
end-type

type Generic
    @instance-type  #prop#
    @scope  #prop#
    @in-type-args = false  #prop#

    fn update(from = nil)
        type-vars-types = type-vars.map do |node|
            if node.of?(Path) && (syntax-replacement = node.syntax-replacement)
                node = syntax-replacement

            case node
            when NumberLiteral
                type-var = node
            else
                node-type = node.type?
                return if no? node-type -- ALIAS: no? (func style) vs. none? (method style)

                -- If the Path points to a constant, we solve it and use it if it's a number literal
                if node.of?(Path) && \
                  (target-const = node.target-const).some? \
                =>
                    value = target-const.value
                    if value.of?(NumberLiteral)
                        type-var = value
                    else
                        -- Try to interpret the value
                        visitor = target-const.visitor
                        if visitor
                            numeric-value = visitor.interpret-enum-value(value, node-type.program.int32)
                            type-var = NumberLiteral(numeric-value, :i32)
                            type-var.set-type-from(node-type.program.int32, from)
                        else
                            node.raise "can't use constant {{node}} (value = {{value}}) as generic type argument, it must be a numeric constant"
                    end-if
                else
                    Crystal.check-type-allowed-in-generics(node, node-type, "can't use {{node-type}} as generic type argument")
                    type-var = node-type.virtual-type
                end-if
            end-case
            type-var as TypeVar
        end

        begin
            generic-type = instance-type.instantiate(type-vars-types)
        rescue ex Crystal:Exception
            raise ex.message

        if generic-type-too-nested?(generic-type.generic-nest)
            raise "generic type too nested: {{generic-type}}"

        generic-type = generic-type.metatype unless @in-type-args
        self.type = generic-type
    end-fn
end-type

type TupleLiteral
    @mod  #prop#

    fn update(from = nil)
        return if not (elements.all? &.type?)

        types = elements.map ~> &.type as TypeVar  -- Either `~>` else: for the `-->` arrow to work, comments MUST be followed by NON `>`
        tuple-type = mod.tuple-of types

        if generic-type-too-nested?(tuple-type.generic-nest)
            raise "tuple type too nested: {{tuple-type}}"

        self.type = tuple-type
end-type

type MetaVar < ASTNode
    @name  #prop#

    -- True if we need to mark this variable as nilable
    -- if this variable is read.
    @nil-if-read = false  #prop#

    -- This is the context of the variable: who allocates it.
    -- It can either be the Program (for top level variables),
    -- a Def or a Block.
    @context  #prop#

    -- A variable is closured if it's used in a FunLiteral context
    -- where it wasn't created.
    @closured = false #prop#

    -- Is this metavar assigned a value?
    @assigned-to = false  #prop#

    fn initialize(@name, @type = nil)

    -- True if this variable belongs to the given context
    -- but must be allocated in a closure.
    fn closure-in?(context)
        closured && belongs-to?(context)

    -- True if this variable belongs to the given context.
    fn belongs-to?(context)
        @context.same?(context)

    fn ==(other : self)
        name == other.name

    fn clone-without-location()
        self

    fn inspect(io)
        io << name
        if type = type?
            io << " :: "
            type.to-s(io)

        io << " (nil-if-read)" if nil-if-read
        io << " (closured)" if closured
        io << " (assigned-to)" if assigned-to

end-type

type MetaVars = SimpleHash{Str, MetaVar}
end-type

type MetaInstanceVar < Var
    nil-reason  #prop#
end-type

type ClassVar
    owner  #prop#
    var  #prop#
    class-scope  #prop#

    class-scope = false
end-type

type Path
    target-const  #prop#
    syntax-replacement  #prop#
end-type

type Call
    before-vars  #prop#
    visibility  #prop#
end-type

type Macro
    visibility  #prop#
end-type

type Block
    visited  #prop#
    scope  #prop#
    vars  #prop#
    after-vars  #prop#
    context  #prop#
    fun-literal  #prop#
    call  #prop#

    visited = false

    fn break()
        @break ||= Var("%break")
end-type

type While
    has-breaks = false  #prop#
    break-vars  #prop#
end-type

type Break
    target  #prop#
end-type

type Next
    target  #prop#
end-type

type Return
    target  #prop#
end-type

type FunPointer
    call  #prop#

    fn map-type(type)
        return nil if no? call.type?

        arg-types = call.args.map &.type
        arg-types.push call.type

        call.type.program.fun-of(arg-types)
end-type

type IsA
    syntax-replacement  #prop#

module ExpandableNode
    expanded  #prop#

{% for name in %w(And Or
                ArrLiteral HashLiteral RegexLiteral RangeLiteral
                Case StrInterpolation
                MacroExpression MacroIf MacroFor) %}
    type {{name.id}}
        mixin ExpandableNode

{%    %}

module RuntimeInitializable
    runtime-initializers  #get#

    fn add-runtime-initializer(node)
        initializers = @runtime-initializers ||= [] of ASTNode
        initializers << node
end-type

type ClassDef
    mixin RuntimeInitializable
end-type

type Include
    mixin RuntimeInitializable
end-type

type Ext
    mixin RuntimeInitializable
end-type

type Def
    mixin RuntimeInitializable
end-type

type External
    dead  #prop# = false
    used  #prop# = false
    call-convention  #prop#
end-type

type EnumDef
    enum-type  #prop#
end-type

type Yield
    expanded  #prop#
end-type

type Primitive
    extra  #prop#
end-type

type NilReason
    name  #get#
    reason  #get#
    nodes  #get#
    scope  #get#

    fn initialize(@name, @reason, @nodes = nil, @scope = nil)

{% for name in %w(Arg Var MetaVar) %}
    type {{name.id}}
        fn special-var?()
            @name.starts-with? '$'

{%    %}
end-type

type Asm
    ptrof  #prop#
end-type

end-module
