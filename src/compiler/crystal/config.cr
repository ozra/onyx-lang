require "../onyx/version_number"

module Crystal
  module Config
    PATH      = {{ env("ONYX_CONFIG_PATH") || env("CRYSTAL_CONFIG_PATH") || "" }}
    VERSION   = ONYX_VERSION

    def self.path
      PATH
    end

    def self.version
      VERSION
    end

    def self.description
      tag, sha = tag_and_sha
      if sha
        "Onyx #{tag} [#{sha}] (#{date})"
      else
        "Onyx #{tag} (#{date})"
      end
    end

    def self.tag_and_sha
      pieces = version.split("-")
      tag = pieces[0]? || "?"
      sha = pieces[2]?
      if sha
        sha = sha[1..-1] if sha.starts_with? 'g'
      end
      {tag, sha}
    end

    def self.date
      {{ `date "+%Y-%m-%d"`.stringify.chomp }}
    end
  end
end
