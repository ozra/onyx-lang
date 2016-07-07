require "../onyx/version_number"

module Crystal
  module Config
    def self.path
      {{ env("ONYX_CONFIG_PATH") || env("CRYSTAL_CONFIG_PATH") || "" }}
    end

    def self.version
      version_and_sha.first
    end

    def self.description
      version, sha = version_and_sha
      # if sha
      #   "Onyx #{version} [#{sha}] (#{date})"
      # else
        "Onyx #{version} (#{date})"
      # end
    end

    # @@version_and_sha : {String, String?}?

    def self.version_and_sha
      {ONYX_VERSION, nil}
      # @@version_and_sha ||= compute_version_and_sha
    end

    def self.date
      {{ `date "+%Y-%m-%d"`.stringify.chomp }}
    end
  end
end
