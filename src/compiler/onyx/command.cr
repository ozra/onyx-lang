require "json"

module Crystal
  def self.tempfile(basename)
    Dir.mkdir_p Config.cache_dir
    File.join(Config.cache_dir, "onyx-run-#{basename}.tmp")
  end
end

class Crystal::OnyxCommand
  USAGE = <<-USAGE
Usage: onyx [command] [switches] [program file] [--] [arguments]

Commands:

  Compilation:
    devel                    compile development program file
    release                  compile release program file
    run  (default)           compile and run program file
    eval                     eval code from args or standard input
    spec                     compile and run specs (in spec directory)
    docs                     generate documentation

  Analytics:
    context                  show context for given location
    hierarchy                show type hierarchy
    implementations          show implementations for given call in location
    types                    show type of main variables

  Source:
    init                     generate new Onyx project
    deps                     install project dependencies
    stylize                  reformat source according to preferences
    onyxify                  convert crystal sources to onyx

  Other:
    --help, -h               show this help
    --version, -v            show version

USAGE


  VALID_EMIT_VALUES = %w(asm llvm-bc llvm-ir obj)

  def self.run(options = ARGV)
    new(options).run
  end

  def initialize(@options)
    @color = true
  end

  private getter options

  def run
    command = options.first?

    if command
      case
      when "init".starts_with?(command)
        options.shift
        init(:onyx)
      # when "init-cr".starts_with?(command)
      #   options.shift
      #   init(:crystal)
      when "parse".starts_with?(command)
        options.shift
        parse_command
      when "build".starts_with?(command)
        error "Use either 'release' or 'devel' specifically"
      when "release".starts_with?(command)
        options.shift
        build(:release)
      when "devel".starts_with?(command)
        options.shift
        build(:devel)
      when "deps".starts_with?(command)
        options.shift
        deps
      when "docs".starts_with?(command)
        options.shift
        docs
      when "eval".starts_with?(command)
        options.shift
        eval
      when "run".starts_with?(command)
        options.shift
        run_command
      when "spec/".starts_with?(command)
        options.shift
        run_specs

      when "context".starts_with?(command)
        options.shift
        context
      when "hierarchy".starts_with?(command)
        options.shift
        hierarchy
      when "implementations".starts_with?(command)
        options.shift
        implementations
      when "types".starts_with?(command)
        options.shift
        types

      when "stylize".starts_with?(command)
        options.shift
        stylize
      when "onyxify".starts_with?(command)
        options.shift
        onyxify
      when "_to_s_".starts_with?(command)
        options.shift
        to_s_debug

      when "--help" == command, "-h" == command
        puts USAGE
        exit
      when "--version" == command, "-v" == command
        puts "Onyx #{Crystal.version_string}"
        exit
      else
        if File.file?(command)
          run_command
        else
          error "unknown command: #{command}"
        end
      end
    else
      puts USAGE
      exit
    end
  rescue ex : Crystal::Exception
    ex.color = @color
    if @config.try(&.output_format) == "json"
      puts ex.to_json
    else
      puts ex
    end
    exit 1
  rescue ex
    puts ex
    ex.backtrace.each do |frame|
      puts frame
    end
    puts
    error "You've found a bug in the Onyx compiler. Please open an issue, including source code that will allow us to reproduce the bug: https://github.com/ozra/onyx-lang/issues"
  end

  private def init(base_lang)
    # if base_lang == :onyx
      # *TODO*
      error "Implement me!"
      Init.run(options)
    # else
    #   Init.run(options)
    # end
  end

  private def build(mode = :devel)
    config = setup_compiler "build"
    if mode == :release
      config.compiler.release = true
    else
      config.compiler.release = false
    end

    config.compile
  end

  private def eval
    if options.empty?
      program_source = STDIN.gets_to_end
      program_args = [] of String
    else
      double_dash_index = options.index("--")
      if double_dash_index
        program_source = options[0...double_dash_index].join " "
        program_args = options[double_dash_index + 1..-1]
      else
        program_source = options.join " "
        program_args = [] of String
      end
    end

    compiler = Compiler.new
    sources = [Compiler::Source.new("eval", program_source)]

    output_filename = tempfile "eval"

    result = compiler.compile sources, output_filename
    execute output_filename, program_args
  end

  private def hierarchy
    config, result = compile_no_codegen "tool hierarchy", hierarchy: true
    Crystal.print_hierarchy result.program, config.hierarchy_exp
  end

  private def implementations
    cursor_command("implementations") do |location, config, result|
      result = ImplementationsVisitor.new(location).process(result)
    end
  end

  private def context
    cursor_command("context") do |location, config, result|
      result = ContextVisitor.new(location).process(result)
    end
  end

  private def cursor_command(command)
    config, result = compile_no_codegen command, cursor_command: true

    format = config.output_format

    file = ""
    line = ""
    col = ""

    loc = config.cursor_location.not_nil!.split(':')
    if loc.size == 3
      file, line, col = loc
    end

    file = File.expand_path(file)

    result = yield Location.new(line.to_i, col.to_i, file), config, result

    case format
    when "json"
      result.to_json(STDOUT)
    else
      result.to_text(STDOUT)
    end
  end

  private def run_command
    config = setup_compiler "run", run: true
    if config.specified_output
      config.compile
      return
    end

    output_filename = tempfile(config.output_filename)

    result = config.compile output_filename
    execute output_filename, config.arguments unless config.compiler.no_codegen?
  end

  private def run_specs
    target_index = options.index { |o| !o.starts_with? '-' }
    if target_index
      target_filename_and_line_number = options[target_index]
      splitted = target_filename_and_line_number.split ':', 2
      target_filename = splitted[0]
      if File.file?(target_filename)
        options.delete_at target_index
        cwd = Dir.current
        if target_filename.starts_with?(cwd)
          target_filename = "#{target_filename[cwd.size..-1]}"
        end
        if splitted.size == 2
          target_line = splitted[1]
          options << "-l" << target_line
        end
      elsif File.directory?(target_filename)
        target_filename = "#{target_filename}/**"
      else
        error "'#{target_filename}' is not a file"
      end
    else
      target_filename = "spec/**"
    end

    sources = [Compiler::Source.new("spec", %(require "./#{target_filename}"))]

    output_filename = tempfile "spec"

    compiler = Compiler.new
    result = compiler.compile sources, output_filename
    execute output_filename, options
  end

  private def deps
    path_to_shards = `which shards`.chomp
    if path_to_shards.empty?
      error "`shards` executable is missing. Please install shards: https://github.com/ysbaddaden/shards"
    end

    Process.run(path_to_shards, args: options, output: true, error: true)
  end

  private def docs
    # *TODO* debug
    _dbg "generate docs"

    if options.empty?
      sources = [Compiler::Source.new("require", %(require "./src/**"))]
      included_dirs = [] of String
    else
      filenames = options
      sources = gather_sources(filenames)
      included_dirs = sources.map { |source| File.dirname(source.filename) }
    end

    included_dirs << File.expand_path("./src")

    output_filename = tempfile "docs"

    compiler = Compiler.new
    compiler.wants_doc = true

    do_link_flags_rationalism! compiler

    result = compiler.compile sources, output_filename
    Crystal.generate_docs result.program, included_dirs
  end

  private def types
    config, result = compile_no_codegen "tool types"
    Crystal.print_types result.original_node
  end


  private def parse_command
    config = setup_compiler "parse", no_codegen: true

    if config.output_format != "ast"
      STDERR.puts "Sorry, parse and dump ast is all I know how to do! ('onyx parse --ast ...')"
      exit 1
    end

    config.sources.each do |source|
      # code = File.read source.filename
      if source.filename.ends_with?(".cr")
        parser = Parser.new source.code
      else
        parser = OnyxParser.new source.code
      end
      parser.filename = source.filename
      parser.wants_doc = true
      node = parser.parse
      node.dump_std
    end
  end

  private def stylize()
    config = setup_compiler "onyxify", no_codegen: true

    config.sources.each do |source|
      # code = File.read source.filename
      if source.filename.ends_with?(".cr")
        parser = Parser.new source.code
      else
        parser = OnyxParser.new source.code
      end
      parser.filename = source.filename
      parser.wants_doc = true
      node = parser.parse
      node.stylize STDOUT, {nop: true}, source.code
    end
  end

  private def onyxify
    stylize()
  end

  private def to_s_debug
    config = setup_compiler "just_to_s", no_codegen: true

    config.sources.each do |source|
      # code = File.read source.filename
      if source.filename.ends_with?(".cr")
        parser = Parser.new source.code
      else
        parser = OnyxParser.new source.code
      end
      parser.filename = source.filename
      parser.wants_doc = true
      node = parser.parse
      node.to_s STDOUT, :onyx
    end
  end

  private def compile_no_codegen(command, wants_doc = false, hierarchy = false, cursor_command = false)
    config = setup_compiler command, no_codegen: true, hierarchy: hierarchy, cursor_command: cursor_command
    config.compiler.no_codegen = true
    config.compiler.wants_doc = wants_doc
    {config, config.compile}
  end

  private def execute(output_filename, run_args)
    begin
      status = Process.run(output_filename, args: run_args, input: true, output: true, error: true)
    ensure
      File.delete output_filename
    end

    if status.normal_exit?
      exit status.exit_code
    else
      case status.exit_signal
      when Signal::KILL
        STDERR.puts "Program was killed"
      when Signal::SEGV
        STDERR.puts "Program exited because of a segmentation fault (11)"
      else
        STDERR.puts "Program received and didn't handle signal #{status.exit_signal} (#{status.exit_signal.value})"
      end

      exit 1
    end
  end

  private def tempfile(basename)
    Crystal.tempfile(basename)
  end

  record CompilerConfig, compiler, sources, output_filename, original_output_filename, arguments, specified_output, hierarchy_exp, cursor_location, output_format do
    def compile(output_filename = self.output_filename)
      compiler.original_output_filename = original_output_filename
      compiler.compile sources, output_filename
    end
  end

  private def setup_compiler(command, no_codegen = false, run = false, hierarchy = false, cursor_command = false)
    compiler = Compiler.new
    link_flags = [] of String
    opt_filenames = nil
    opt_arguments = nil
    opt_output_filename = nil
    specified_output = false
    hierarchy_exp = nil
    cursor_location = nil
    output_format = nil

    option_parser = OptionParser.parse(options) do |opts|
      opts.banner = "Usage: crystal #{command} [options] [programfile] [--] [arguments]\n\nOptions:"

      opts.on("--ast", "Dump AST to .onyx-cache directory") do
        no_codegen = true
        output_format = "ast"
      end

      unless no_codegen
        unless run
          opts.on("--cross-compile flags", "cross-compile") do |cross_compile|
            compiler.cross_compile_flags = cross_compile
          end
        end
        opts.on("-d", "--debug", "Add symbolic debug info") do
          compiler.debug = true
        end
      end

      opts.on("-D FLAG", "--define FLAG", "Define a compile-time flag") do |flag|
        compiler.add_flag flag
      end

      unless no_codegen
        opts.on("--emit [#{VALID_EMIT_VALUES.join("|")}]", "Comma separated list of types of output for the compiler to emit") do |emit_values|
          compiler.emit = validate_emit_values(emit_values.split(',').map(&.strip))
        end
      end

      if hierarchy
        opts.on("-e NAME", "Filter types by NAME regex") do |exp|
          hierarchy_exp = exp
        end
      end

      if cursor_command
        opts.on("-c LOC", "--cursor LOC", "Cursor location with LOC as path/to/file.cr:line:column") do |cursor|
          cursor_location = cursor
        end
      end

      opts.on("-f text|json", "--format text|json", "Output format text (default) or json") do |f|
        output_format = f
      end

      opts.on("-h", "--help", "Show this message") do
        puts opts
        exit 1
      end

      unless no_codegen
        opts.on("--ll", "Dump ll to .onyx-cache directory") do
          compiler.dump_ll = true
        end
        opts.on("--link-flags FLAGS", "Additional flags to pass to the linker") do |some_link_flags|
          link_flags << some_link_flags
        end
        opts.on("--mcpu CPU", "Target specific cpu type") do |cpu|
          compiler.mcpu = cpu
        end
      end

      opts.on("--no-color", "Disable colored output") do
        @color = false
        compiler.color = false
      end

      unless no_codegen
        opts.on("--no-codegen", "Don't do code generation") do
          compiler.no_codegen = true
        end
        opts.on("-o ", "Output filename") do |an_output_filename|
          opt_output_filename = an_output_filename
          specified_output = true
        end
      end

      opts.on("--prelude ", "Use given file as prelude") do |prelude|
        compiler.prelude = prelude
      end

      unless no_codegen
        # debug_release_flags = 0
        # opts.on("--devel", "Compile in devel mode") do
        #   compiler.release = false
        #   p "Got --devel"
        #   debug_release_flags += 1
        # end
        # opts.on("--release", "Compile in release mode") do
        #   compiler.release = true
        #   p "Got --release"
        #   debug_release_flags += 1
        # end
        opts.on("-s", "--stats", "Enable statistics output") do
          compiler.stats = true
        end
        opts.on("--single-module", "Generate a single LLVM module") do
          compiler.single_module = true
        end
        opts.on("--threads ", "Maximum number of threads to use") do |n_threads|
          compiler.n_threads = n_threads.to_i
        end
        unless run
          opts.on("--target TRIPLE", "Target triple") do |triple|
            compiler.target_triple = triple
          end
        end
        opts.on("--verbose", "Display executed commands") do
          compiler.verbose = true
        end

        # if debug_release_flags > 1  # both debug and release (!?)
        #   error "can't supply both --debug and --release - pick one!"

        # elsif debug_release_flags == 0 && run == false  # neither
        #   error "either --debug or --release must be specified"
        # end
      end

      opts.unknown_args do |before, after|
        opt_filenames = before
        opt_arguments = after
      end
    end

    compiler.link_flags = link_flags.join(" ") unless link_flags.empty?
    do_link_flags_rationalism! compiler

    output_filename = opt_output_filename
    filenames = opt_filenames.not_nil!
    arguments = opt_arguments.not_nil!

    if filenames.size == 0 || (cursor_command && cursor_location.nil?)
      puts option_parser
      exit 1
    end

    sources = gather_sources(filenames)
    original_output_filename = output_filename_from_sources(sources)
    output_filename ||= original_output_filename
    output_format ||= "text"

    if !no_codegen && Dir.exists?(output_filename)
      error "can't use `#{output_filename}` as output filename because it's a directory"
    end

    @config = CompilerConfig.new compiler, sources, output_filename, original_output_filename, arguments, specified_output, hierarchy_exp, cursor_location, output_format

  rescue ex : OptionParser::Exception
    error ex.message
  end

  private def gather_sources(filenames)
    filenames.map do |filename|
      unless File.file?(filename)
        error "File #{filename} does not exist"
      end
      filename = File.expand_path(filename)
      Compiler::Source.new(filename, File.read(filename))
    end
  end

  private def output_filename_from_sources(sources)
    first_filename = sources.first.filename
    File.basename(first_filename, File.extname(first_filename))
  end

  private def validate_emit_values(values)
    values.each do |value|
      unless VALID_EMIT_VALUES.includes?(value)
        error "invalid emit value '#{value}'"
      end
    end
    values
  end

  private def do_link_flags_rationalism!(compiler) : Nil
    _dbg "compiler.link_flags = #{compiler.link_flags}"

    lflags = compiler.link_flags || ""

    if lflags.index("-L") == nil
      # *TODO* curr dir seems a bit impossible to do cross platform
      # meanwhile another non cross platform hack is in place :-/
      curr_dir = `which onyx`

      out_flags =
        case
        when Dir.exists? "#{curr_dir}/lib/onyx/embedded/lib"
          lflags + " -L#{curr_dir}/lib/onyx/embedded/lib"

        when Dir.exists? "#{curr_dir}/../embedded/lib"
          lflags + " -L#{curr_dir}/../embedded/lib"

        when Dir.exists? "/opt/onyx/embedded/lib"
          lflags + " -L/opt/onyx/embedded/lib"

        when Dir.exists? "/usr/local/lib/onyx/embedded/lib"
          lflags + " -L/usr/local/lib/onyx/embedded/lib"

        else
          lflags
          # We don't know how to try to help - let's hope the system is actually setup right ;-)
        end

      _dbg "compiler.link_flags massaged to: #{out_flags}"
      compiler.link_flags = out_flags
      return

    else
      return
    end
  end

  private def error(msg)
    # This is for the case where the main command is wrong
    @color = false if ARGV.includes?("--no-color")
    Crystal.error msg, @color
  end
end
