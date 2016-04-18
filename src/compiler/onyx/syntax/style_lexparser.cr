require "../../crystal/syntax/to_s"

module Crystal

abstract class ASTNode
   property literal_style
   @literal_style = :original
end

class StringLiteral < ASTNode
   property string_style
   @string_style = :quoted
end

class Def < ASTNode
   property def_base_style
   @def_base_style = :arrow

   def literal_prefix_keyword=(flag : Symbol)
      # *TODO*
      @detail_flags |= 0
   end
end

class StyleParseVisitor < Visitor
   @src : Array(Array(Char))

   def initialize(conf : Hash(String, String), src : String)
      @conf = conf || Hash(String, String).new
      @org_src = src
      @src = src.split(/\n/).map &.chars
      @inside_macro = 0
      @inside_lib = false
   end


   # # # # #
   # Utils #
   # # # # #

   def get_src_idfr(node : ASTNode)
      # *TODO* find reasonable sub–node for name, then parse from it's position

   end

   def is_alpha(string)
      'a' <= string[0].downcase <= 'z'
   end


   # # # # # # # # # #
   # Specific nodes  #
   # # # # # # # # # #

   def visit(node : Primitive)
   end

   def visit(node : Nop)
   end

   def visit(node : BoolLiteral)
   end

   def visit(node : NumberLiteral)
   end

   def visit(node : CharLiteral)
   end

   def visit(node : SymbolLiteral)
   end

   def visit(node : StringLiteral)
   end

   def visit(node : StringInterpolation)
   end

   def visit(node : ArrayLiteral)
   end

   def visit(node : HashLiteral)
   end

   def visit(node : NilLiteral)
   end

   def visit(node : Expressions)
   end

   def visit(node : If)
   end

   def visit(node : Unless)
   end

   def visit(node : IfDef)
   end

   def visit(node : ClassDef)
   end

   def visit(node : ModuleDef)
   end

   def visit(node : Call)
   end

   def visit(node : NamedArgument)
   end

   def visit(node : MacroId)
   end

   def visit(node : TypeNode)
   end

   def visit(node : Assign)
   end

   def visit(node : MultiAssign)
   end

   def visit(node : For)
   end

   def visit(node : While)
   end

   def visit(node : Until)
   end

   def visit(node : Out)
   end

   def visit(node : Var)
   end

   def visit(node : MetaVar)
   end

   def visit(node : FunLiteral)
   end

   def visit(node : FunPointer)
   end

   def visit(node : Def)
   end

   def visit(node : Macro)
   end

   def visit(node : MacroExpression)
   end

   def visit(node : MacroIf)
   end

   def visit(node : MacroFor)
   end

   def visit(node : MacroVar)
   end

   def visit(node : MacroLiteral)
   end

   def visit(node : External)
   end

   def visit(node : ExternalVar)
   end

   def visit(node : Arg)
   end

   # def visit(node : BlockArg)
   # end

   def visit(node : Fun)
   end

   def visit(node : Self)
   end

   def visit(node : Path)
   end

   def visit(node : Generic)
   end

   def visit(node : Underscore)
   end

   def visit(node : Splat)
   end

   def visit(node : Union)
   end

   # def visit(node : Virtual)
   # end

   def visit(node : Metaclass)
   end

   def visit(node : InstanceVar)
   end

   def visit(node : ReadInstanceVar)
   end

   def visit(node : ClassVar)
   end

   def visit(node : Yield)
   end

   def visit(node : Return)
   end

   def visit(node : Break)
   end

   def visit(node : Next)
   end

   def visit(node : RegexLiteral)
   end

   def visit(node : TupleLiteral)
   end

   def visit(node : TypeDeclaration)
   end

   def visit(node : Block)
   end

   def visit(node : Include)
   end

   def visit(node : Extend)
   end

   def visit(node : And)
   end

   def visit(node : Or)
   end

   def visit(node : Not)
   end

   def visit(node : VisibilityModifier)
   end

   def visit(node : TypeFilteredNode)
   end

   def visit(node : Global)
   end

   def visit(node : LibDef)
   end

   def visit(node : FunDef)
   end

   def visit(node : TypeDef)
   end

   def visit(node : StructDef)
   end

   def visit(node : UnionDef)
   end

   def visit(node : EnumDef)
   end

   def visit(node : RangeLiteral)
   end

   def visit(node : PointerOf)
   end

   def visit(node : SizeOf)
   end

   def visit(node : InstanceSizeOf)
   end

   def visit(node : IsA)
   end

   def visit(node : Cast)
   end

   def visit(node : RespondsTo)
   end

   def visit(node : Require)
   end

   def visit(node : Case)
   end

   def visit(node : When)
   end

   def visit(node : ImplicitObj)
   end

   def visit(node : ExceptionHandler)
   end

   def visit(node : Rescue)
   end

   def visit(node : Alias)
   end

   def visit(node : TypeOf)
   end

   def visit(node : Attribute)
   end

   def visit(node : MagicConstant)
   end

   def visit(node : Asm)
   end

   def visit(node : AsmOperand)
   end
end

end # module
