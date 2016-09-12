require "option_parser"
require "file_utils"
require "socket"
require "colorize"
require "crypto/md5"

module Crystal
  # Main interface to the compiler.
  #
  # A Compiler parses source code, type checks it and
  # optionally generates an executable.
  class Compiler
    CC = ENV["CC"]? || "cc"
    LD_ADD = "LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH"
    DEFAULT_LIBBING = "-L/opt/onyx/embedded/lib -L/usr/local/lib"

    # A source to the compiler: it's filename and source code.
    record Source,
      filename : String,
      code : String

    # The result of a compilation: the program containing all
    # the type and method definitions, and the parsed program
    # as an ASTNode.
    record Result,
      program : Program,
      node : ASTNode

    # If `true`, doesn't generate an executable but instead
    # creates a `.o` file and outputs a command line to link
    # it in the target machine.
    property cross_compile = false

    # Compiler flags. These will be true when checked in macro
    # code by the `flag?(...)` macro method.
    property flags = [] of String

    # If `true`, the executable will be generated with debug code
    # that can be understood by `gdb` and `lldb`.
    property? debug = false

    # If `true`, `.ll` files will be generated in the default cache
    # directory for each generated LLVM module.
    property? dump_ll = false

    # Additional link flags to pass to the linker.
    property link_flags : String?

    # Sets the mcpu. Check LLVM docs to learn about this.
    property mcpu : String?

    # If `false`, color won't be used in output messages.
    property? color = true

    # If `true`, no executable will be generated after compilation
    # (useful to type-check a prorgam)
    property? no_codegen = false

    # Maximum number of LLVM modules that are compiled in parallel
    property n_threads = 8
    property n_concurrent = 1000

    # Default prelude file to use. This ends up adding a
    # `require "prelude"` (or whatever name is set here) to
    # the source file to compile.
    property prelude = "onyx_prelude"

    # If `true`, runs LLVM optimizations.
    property? release = false

    # If `true`, generates a single LLVM module. By default
    # one LLVM module is created for each type in a program.
    property? single_module = false

    # If `true`, prints time and memory stats to `stdout`.
    property? stats = false

    # Target triple to use in the compilation.
    # If not set, asks LLVM the default one for the current machine.
    property target_triple : String?

    # If `true`, prints the link command line that is performed
    # to create the executable.
    property? verbose = false

    # If `true`, doc comments are attached to types and methods
    # and can later be used to generate API docs.
    property? wants_doc = false

    # Can be set to an array of strings to emit other files other
    # than the executable file:
    # * asm: assembly files
    # * llvm-bc: LLVM bitcode
    # * llvm-ir: LLVM IR
    # * obj: object file
    property emit : Array(String)?

    # Base filename to use for `emit` output.
    property emit_base_filename : String?

    # By default the compiler cleans up the default cache directory
    # to keep the most recent 10 directories used. If this is set
    # to `false` that cleanup is not performed.
    property? cleanup = true

    # Default standard output to use in a compilation.
    property stdout : IO = STDOUT

    # Default standard error to use in a compilation.
    property stderr : IO = STDERR

    # Compiles the given *source*, with *output_filename* as the name
    # of the generated executable.
    #
    # Raises `Crystal::Exception` if there's an error in the
    # source code.
    #
    # Raies `InvalidByteSequenceError` if the source code is not
    # valid UTF-8.
    def compile(source : Source | Array(Source), output_filename : String) : Result
      source = [source] unless source.is_a?(Array)
      program = new_program(source)
      node = parse program, source
      node = program.semantic node, @stats
      codegen program, node, source, output_filename unless @no_codegen
      Result.new program, node
    end

    # Runs the semantic pass on the given source, without generating an
    # executable nor analyzing methods. The returned `Program` in the result will
    # contain all types and methods. This can be useful to generate
    # API docs, analyze type relationships, etc.
    #
    # Raises `Crystal::Exception` if there's an error in the
    # source code.
    #
    # Raies `InvalidByteSequenceError` if the source code is not
    # valid UTF-8.
    def top_level_semantic(source : Source | Array(Source)) : Result
      source = [source] unless source.is_a?(Array)
      program = new_program(source)
      node = parse program, source
      node, processor = program.top_level_semantic(node, @stats)
      Result.new program, node
    end

    private def new_program(sources)
      program = Program.new
      program.cache_dir = CacheDir.instance.directory_for(sources)
      program.target_machine = target_machine
      program.flags << "release" if @release
      program.flags.merge @flags
      program.wants_doc = wants_doc?
      program.color = color?
      program.stdout = stdout
      program
    end

    private def parse(program, sources : Array)
      Crystal.timing("Parse", @stats) do
        nodes = sources.map do |source|
          # We add the source to the list of required file,
          # so it can't be required again
          program.add_to_requires source.filename
          parse(program, source).as(ASTNode)
        end
        nodes = Expressions.from(nodes)

        # Prepend the prelude to the parsed program
        nodes = Expressions.new([Require.new(prelude), nodes] of ASTNode)

        # And normalize
        program.normalize(nodes)
      end
    end

    private def parse(program, source : Source)
      _dbg_overview "\nCompiler stage: Compiler.parse \"#{source.filename}\"\n\n".white

      if source.filename.ends_with? ".cr"
        parser = Parser.new(source.code, program.string_pool)
      else # .ox, .onyx
        parser = OnyxParser.new(source.code, program.string_pool)
      end
      parser.filename = source.filename
      parser.wants_doc = wants_doc?
      parser.parse
    rescue ex : InvalidByteSequenceError
      stdout.print colorize("Error: ").red.bold
      stdout.print colorize("file '#{Crystal.relative_filename(source.filename)}' is not a valid Crystal source file: ").bold
      stdout.puts "#{ex.message}"
      exit 1
    end

    private def codegen(program : Program, node, sources, output_filename)

      _dbg_overview "\nCompiler stage: Compiler.codegen (node) \"#{output_filename}\"\n\n".white

      @link_flags = "#{@link_flags} -rdynamic"
      bc_flags_md5 = Crypto::MD5.hex_digest "#{@target_triple}#{@mcpu}#{@release}#{@link_flags}"
      lib_flags = program.lib_flags

      llvm_modules = Crystal.timing("Codegen (onyx)", @stats) do
        program.codegen node, debug: @debug, single_module: @single_module || @release || @cross_compile || @emit, expose_crystal_main: false
      end

      if @cross_compile
        output_dir = "."
      else
        output_dir = CacheDir.instance.directory_for(sources)
      end

      units = llvm_modules.map do |type_name, llvm_mod|
        CompilationUnit.new(self, type_name, llvm_mod, output_dir, bc_flags_md5)
      end

      lib_flags = program.lib_flags

      if @cross_compile
        cross_compile program, units, lib_flags, output_filename
      else
        codegen program, units, lib_flags, output_filename, output_dir
      end

      CacheDir.instance.cleanup if @cleanup
    end

    private def cross_compile(program, units, lib_flags, output_filename)

      _dbg_overview "\nCompiler stage: Compiler.cross_compile \"#{output_filename}.o\"\n\n".white

      llvm_mod = units.first.llvm_mod
      object_name = "#{output_filename}.o"

      if @release
        Crystal.timing("LLVM Optimizer", @stats) do
          optimize llvm_mod
        end
      end

      llvm_mod.print_to_file object_name.gsub(/\.o/, ".ll") if dump_ll?
      target_machine.emit_obj_to_file llvm_mod, object_name

      stdout.puts "\nUse the following command on the target platform to link the cross compiled object:"
      stdout.puts "#{LD_ADD}  #{CC} #{object_name} -o #{output_filename} #{@link_flags} #{lib_flags} #{DEFAULT_LIBBING}".yellow
    end

    private def codegen(program, units : Array(CompilationUnit), lib_flags, output_filename, output_dir)

      _dbg_overview "\nCompiler stage: Compiler.codegen (units) \"#{output_filename}\"\n\n".white

      object_names = units.map &.object_filename
      target_triple = target_machine.triple

      Crystal.timing("Codegen (bc+obj)", @stats) do
        if units.size == 1
          first_unit = units.first

          codegen_single_unit(program, first_unit, target_triple)

          if emit = @emit
            first_unit.emit(emit, emit_base_filename || output_filename)
          end
        else
          codegen_many_units(program, units, target_triple)
        end
      end

      # We check again because maybe this directory was created in between (maybe with a macro run)
      if Dir.exists?(output_filename)
        error "can't use `#{output_filename}` as output filename because it's a directory"
      end

      output_filename = File.expand_path(output_filename)

      Crystal.timing("Codegen (linking)", @stats) do
        Dir.cd(output_dir) do
          system %(#{LD_ADD}  #{CC} -o "#{output_filename}" "${@}" #{@link_flags} #{lib_flags} #{DEFAULT_LIBBING}), object_names
        end
      end
    end

    private def codegen_many_units(program, units, target_triple)
      jobs_count = 0
      wait_channel = Channel(Nil).new(@n_concurrent)

      perf_tmp = Time.now

      while unit = units.pop?
        spawn_and_codegen_single_unit(program, unit, target_triple, wait_channel)
        jobs_count += 1

        if jobs_count >= @n_concurrent
          wait_channel.receive
          jobs_count -= 1
        end
      end

      while jobs_count > 0
        wait_channel.receive
        jobs_count -= 1
      end

    end

    private def spawn_and_codegen_single_unit(program, unit, target_triple, wait_channel)
      spawn do
        codegen_single_unit(program, unit, target_triple)
        wait_channel.send nil
      end
    end

    private def codegen_single_unit(program, unit, target_triple)
      unit.llvm_mod.target = target_triple
      # unit.write_bitcode if multithreaded
      unit.compile
    end

    protected def target_machine
      @target_machine ||= begin
        triple = @target_triple || LLVM.default_target_triple
        TargetMachine.create(triple, @mcpu || "", @release)
      end
    rescue ex : ArgumentError
      stdout.print colorize("Error: ").red.bold
      stdout.print "llc: "
      stdout.puts "#{ex.message}"
      exit 1
    end

    protected def optimize(llvm_mod)
      fun_pass_manager = llvm_mod.new_function_pass_manager
      fun_pass_manager.add_target_data target_machine.data_layout
      pass_manager_builder.populate fun_pass_manager
      fun_pass_manager.run llvm_mod
      module_pass_manager.run llvm_mod
    end

    @module_pass_manager : LLVM::ModulePassManager?

    private def module_pass_manager
      @module_pass_manager ||= begin
        mod_pass_manager = LLVM::ModulePassManager.new
        mod_pass_manager.add_target_data target_machine.data_layout
        pass_manager_builder.populate mod_pass_manager
        mod_pass_manager
      end
    end

    @pass_manager_builder : LLVM::PassManagerBuilder?

    private def pass_manager_builder
      @pass_manager_builder ||= begin
        registry = LLVM::PassRegistry.instance
        registry.initialize_all

        builder = LLVM::PassManagerBuilder.new
        builder.opt_level = 3
        builder.size_level = 0
        builder.use_inliner_with_threshold = 275
        builder
      end
    end

    private def system(command, args = nil)
      stdout.puts "#{command} #{args.join " "}" if verbose?

      ::system(command, args)
      unless $?.success?
        msg = $?.normal_exit? ? "code: #{$?.exit_code}" : "signal: #{$?.exit_signal} (#{$?.exit_signal.value})"
        code = $?.normal_exit? ? $?.exit_code : 1
        error "execution of command failed with #{msg}: `#{command}`", exit_code: code
      end
    end

    private def error(msg, exit_code = 1)
      Crystal.error msg, @color, exit_code, stderr: stderr
    end

    private def colorize(obj)
      obj.colorize.toggle(@color)
    end

    # An LLVM::Module with information to compile it.
    class CompilationUnit
      getter compiler
      getter llvm_mod

      def initialize(@compiler : Compiler, @name : String, @llvm_mod : LLVM::Module,
                     @output_dir : String, @bc_flags_md5 : String)
        @name = "_main" if @name == ""
        @name = String.build do |str|
          @name.each_char do |char|
            case char
            when 'a'..'z', '0'..'9', '_'
              str << char
            when 'A'..'Z'
              # Because OSX has case insensitive filenames, try to avoid
              # clash of 'a' and 'A' by using 'A-' for 'A'.
              str << char << '-'
            else
              str << char.ord
            end
          end
        end
        @name += bc_flags_md5

        if @name.size > 50
          # 17 chars from name + 1 (dash) + 32 (md5) = 50
          @name = "#{@name[0..16]}-#{Crypto::MD5.hex_digest(@name)}"
        end
      end

      def buffer_to_slice(buf : LibLLVM::MemoryBufferRef)
        ptr = LibLLVM.get_buffer_start(buf)
        size = LibLLVM.get_buffer_size(buf)
        ret = Slice.new ptr, size
        ret
      end

      def compare_slice_to_file(buffer, filename)
        return false if File.size(filename) != buffer.size

        File.open(filename, "rb") do |file|
          read_buf = uninitialized UInt8[8192]
          read_buf_ptr = read_buf.to_unsafe
          walk_ptr = buffer.to_unsafe
          stop_ptr = buffer.to_unsafe + buffer.size

          while true
            return true if walk_ptr == stop_ptr
            gotten_bytes = file.read read_buf.to_slice
            return false if read_buf_ptr.memcmp(walk_ptr, gotten_bytes) != 0
            walk_ptr += gotten_bytes
          end
        end

        return false
      end

      def tempify_name(filename)
        # Just some reasonable insurance it won't clash with a real filename
        filename + "__TMP__.tmp"
      end

      def via_temp_file(filename, &block)
        tmp_name = tempify_name filename
        yield tmp_name
        File.rename tmp_name, filename
      end

      def write_buf_to_file(buffer, filename)
        via_temp_file(filename) do |tmp_name|
          # Do _not_ use File.write - uses to_s => wrecks comparison
          File.open(tmp_name, "w") { |file| file.write buffer }
        end
      end

      def compile
        can_skip_compile = compiler.emit ? false : true
        # Do this before mem–allocation to keep mem total down (many n_concurrent,
        # and file–ops are rescheduling)
        can_skip_compile &&= File.exists?(object_name)
        can_skip_compile &&= File.exists?(bc_name)

        # To compile a file we first generate a `.bc` file and then
        # create an object file from it. These `.bc` files are stored
        # in the cache directory.
        #
        # On a next compilation of the same project, and if the compile
        # flags didn't change (a combination of the target triple, mcpu,
        # release and link flags, amongst others), we check if the new
        # `.bc` file is exactly the same as the old one. In that case
        # the `.o` file will also be the same, so we simply reuse the
        # old one. Generating an `.o` file is what takes most time.

        bc_buf_ref = LibLLVM.write_bitcode_to_memory_buffer(llvm_mod)
        bc_buf = buffer_to_slice bc_buf_ref
        can_skip_compile &&= compare_slice_to_file bc_buf, bc_name

        if can_skip_compile
          LibLLVM.dispose_memory_buffer bc_buf_ref
        else
          write_buf_to_file bc_buf, bc_name
          LibLLVM.dispose_memory_buffer bc_buf_ref

          compiler.optimize llvm_mod if compiler.release?

          via_temp_file(object_name) do |tmp_name|
            compiler.target_machine.emit_obj_to_file llvm_mod, tmp_name
          end
        end

        if compiler.dump_ll?
          via_temp_file(ll_name) do |tmp_name|
            llvm_mod.print_to_file tmp_name
          end
        end
        nil
      end

      def emit(values : Array, output_filename)
        values.each do |value|
          emit value, output_filename
        end
      end

      def emit(value : String, output_filename)
        case value
        when "asm"
          compiler.target_machine.emit_asm_to_file llvm_mod, "#{output_filename}.s"
        when "llvm-bc"
          FileUtils.cp(bc_name, "#{output_filename}.bc")
        when "llvm-ir"
          llvm_mod.print_to_file "#{output_filename}.ll"
        when "obj"
          FileUtils.cp(object_name, "#{output_filename}.o")
        end
      end

      def object_name
        Crystal.relative_filename("#{@output_dir}/#{object_filename}")
      end

      def object_filename
        "#{@name}.o"
      end

      def bc_name
        "#{@output_dir}/#{@name}.bc"
      end

      def ll_name
        "#{@output_dir}/#{@name}.ll"
      end
    end
  end
end
