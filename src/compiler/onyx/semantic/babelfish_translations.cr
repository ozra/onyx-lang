class BabelData
  @@stringpool = StringPool.new
  @@func_dict = Hash(String, String).new
  @@reverse_dict = Hash(String, String).new

  def self.get_str(str : String)
    @@stringpool.get str
  end

  def self.funcs()
    @@func_dict
  end

  def self.reverse()
    @@reverse_dict
  end
end

babelfish_func_dict = BabelData.funcs
babelfish_reverse_dict = BabelData.reverse

macro babel_func(given, foreign, block_it = true)
  babelfish_func_dict["{{given.id}}"] = "{{foreign.id}}"
  babelfish_reverse_dict["{{foreign.id}}"] = "{{given.id}}"
  {% if block_it %}
    babelfish_func_dict["{{foreign.id}}"] = "{{foreign.id}}__auto_babeled_"
    babelfish_reverse_dict["{{foreign.id}}__auto_babeled_"] = "{{foreign.id}}"
  {% end %}
end


# def babelfish_reverse(name : String) : String
#   BabelData.reverse[name]? || name
# end



babel_func  init,        initialize,         true
babel_func  deinit,      finalize,           true
# babel_func  :class,      itype,              true


babel_func  :"~~",       :"==="

# babel_func  each,        each_with_index,  false
# babel_func  each_,       each,             false

babel_func  is!,           not_nil!,         false

