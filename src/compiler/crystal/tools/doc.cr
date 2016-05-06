require "markdown"

module Crystal
  def self.generate_docs(program, base_dirs)
    _dbg "Time to generate docs!"
    generator = Doc::Generator.new(program, base_dirs)
    generator.run
  end
end
