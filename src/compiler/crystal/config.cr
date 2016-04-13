require "../onyx/version_number"

module Crystal
  module Config
    PATH      = {{ env("ONYX_CONFIG_PATH") || env("CRYSTAL_CONFIG_PATH") || "" }}
    VERSION   = ONYX_VERSION
    CACHE_DIR = ENV["ONYX_CACHE_DIR"]? || ENV["CRYSTAL_CACHE_DIR"]? || ".onyx-cache"

    @@cache_dir : String?

    def self.cache_dir
      @@cache_dir ||= File.expand_path(CACHE_DIR)
    end
  end
end
