module Crystal
  # Manages cache files in the ".crystal" directory.
  #
  # For each compiled program a directory is created in the cache
  # that stores .bc and .o files that could possibly be reused
  # from a previous compilation.
  #
  # To keep the cache dir small, only the 10 most recently used
  # directories are kept. We use the directory's modification
  # time for this.
  class CacheDir
    def self.instance
      @@instance ||= new
    end

    @dir : String?

    private def initialize
    end

    # Returns the directory where cache files related to the
    # given sources will be stored. The directory will be
    # created if it doesn't exist.
    def directory_for(sources : Array(Compiler::Source))
      directory_for(sources.first.filename)
    end

    # Returns the directory where cache files related to the
    # given filenames will be stored. The directory will be
    # created if it doesn't exist.
    def directory_for(filename : String)
      dir = compute_dir

      name = filename.gsub('/', "__")
      while name.starts_with?('_')
        name = name[1..-1]
      end
      output_dir = File.join(dir, name)
      Dir.mkdir_p(output_dir)
      output_dir
    end

    # Keeps the 10 most recently used directories in the cache,
    # and removes all others. This also removes non-directory
    # files inside the cache directory (temporary executables
    # resulting from `crystal run` or `run` macro calls).
    def cleanup
      dir = compute_dir
      entries = gather_cache_entries(dir)
      cleanup_dirs(entries)
      cleanup_files(entries)
    end

    # Returns a filename that has prepended the cache directory.
    def join(filename)
      dir = compute_dir
      File.join(dir, filename)
    end

    # Returns the cache directory.
    def dir
      compute_dir
    end

    private def compute_dir
      dir = @dir
      return dir if dir

      # Try to use one of these as a cache directory, in order
      candidates = [
        ENV["ONYX_CACHE_DIR"]?,
        ENV["XDG_CACHE_HOME"]?.try { |home| "#{home}/onyx" },
        ENV["HOME"]?.try { |home| "#{home}/.cache/onyx" },
        ENV["HOME"]?.try { |home| "#{home}/.onyx-cache" },
        ".onyx-cache",
      ]
      candidates = candidates
        .compact
        .map { |file| File.expand_path(file) }
        .uniq

      # Return the first one for which we could create a directory
      candidates.each do |candidate|
        begin
          Dir.mkdir_p(candidate)
          return @dir = candidate
        rescue Errno
          # Try next one
        end
      end

      msg = String.build do |io|
        io.puts "Error: can't create cache directory."
        io.puts
        io.puts "Crystal needs a cache directory. These directories were candidates for it:"
        io.puts
        candidates.each do |candidate|
          io << " - " << candidate << "\n"
        end
        io.puts
        io.puts "but none of them are writable."
        io.puts
        io.puts "Please specify a writable cache directory by setting the CRYSTAL_CACHE_DIR environment variable."
      end

      puts msg
      exit 1
    end

    private def cleanup_dirs(entries)
      entries
        .select { |dir| Dir.exists?(dir) }
        .sort_by! { |dir| File.stat(dir).mtime rescue Time.epoch(0) }
        .reverse!
        .skip(10)
        .each { |name| `rm -rf "#{name}"` rescue nil }
    end

    private def cleanup_files(entries)
      entries
        .select { |dir| File.file?(dir) }
        .each { |name| File.delete(name) rescue nil }
    end

    private def gather_cache_entries(dir)
      Dir.entries(dir)
         .reject { |name| name == "." || name == ".." }
         .map! { |name| File.join(dir, name) }
    end
  end
end