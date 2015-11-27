require "../../crystal/codegen/debug"

module Crystal
  class CodeGenVisitor
    def file_and_dir(file)
      # @file_and_dir ||= {} of String | VirtualFile => {String, String}
      realfile = case file
                 when String then file
                 when VirtualFile
                   Dir.mkdir_p(".onyx-cache")
                   File.write(".onyx-cache/macro#{file.object_id}.cr", file.source)
                   ".onyx-cache/macro#{file.object_id}.cr"
                 else
                   raise "Unknown file type: #{file}"
                 end
      {
        File.basename(realfile), # File
        File.dirname(realfile),  # Directory
      }
    end
  end
end