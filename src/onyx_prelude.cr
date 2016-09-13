# Entries to this file should only be ordered if macros are involved -
# macros need to be defined before they are used.
# A first compiler pass gathers all classes and methods, removing the
# requirement to place these in load order.
#
# When adding new files, use alpha-sort when possible. Make sure
# to also add them to `docs_main.cr` if their content need to
# appear in the API docs.

require "onyx_prelude_intro"

# This list requires ordered statements
require "lib_c"
require "macros"
require "object"
require "comparable"
require "exception"
require "iterable"
require "iterator"
require "indexable"
require "string"

# Alpha-sorted list
require "array"
require "bool"
require "box"
require "char"
require "char/reader"
require "class"
require "concurrent"
require "deque"
require "dir"
require "enum"
require "enumerable"
require "env"
require "errno"
require "ext"
require "file"
require "float"
ifdef !gc_cc47
   require "gc"
   require "gc/boehm"
end
require "hash"
require "iconv"
require "int"
require "intrinsics"
require "io"
require "kernel"
require "main"
require "math/math"
require "mutex"
require "named_tuple"
require "nil"
require "number"
require "pointer"
require "primitives"
require "proc"
require "process"
require "raise"
require "random"
require "range"
require "reference"
require "reflect"
require "regex"
require "set"
require "signal"
require "slice"
require "static_array"
require "struct"
require "symbol"
require "system"
require "thread"
require "time"
require "tuple"
require "union"
require "value"


ifdef gc_cc47
   require "ext/gc-cc47"
   require "gc"
end

require "onyx_type_primitives_layer"
require "onyx_object_additions"
require "onyx_set_additions"
require "onyx_regex_additions"
require "onyx_corner_stone_layer"
