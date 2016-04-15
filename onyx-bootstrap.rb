#!/usr/bin/env ruby

module Kernel
	def optional_require(feature)
    begin
      require feature; true
    rescue LoadError
			false
    end
  end
end
require 'pathname'
require 'uri'
require 'open-uri'
optional_require 'pry'
module Kernel
	def require_gem(gem, *features, auto_install: false)
		features = features.none? ? [gem] : (features.single? && features[0].is_a?(Array) ? features.first : features)
		failures = features.map { |f| f unless optional_require f }.compact
		if failures.any? && auto_install
			result = execute %{gem install "%s"} % gem
			Gem.clear_paths
			require_gem(gem, *features, auto_install: false)
		else
			fail "Requires %s gem" % gem if failures.length == features.length
			fail "Could not require %s" % failures.join(", ") if failures.any?
		end
	end
end
require_gem 'nokogiri', auto_install: true

class Exception
	@shortform = nil
	def shortform; @shortform || self.class.name; end
	def summarise; "%s (%s)" % [message, self.class.name]; end
end
module Enumerable
	def single(&block)
		values = block_given? ? select(&block) : self
		case length
			when 0
				raise NoValuesException
			when 1
				values.first
			else
				raise MultipleValuesException
		end
	end
	def some?; length > 0; end
end
def define_exceptions(*names)
	names.each { |name|
		raise "Exception '%s' is already defined" % name if Object.const_defined? name
		Object.const_set name.to_s, Class.new(StandardError)
	}
end
define_exceptions :NoValuesException, :MultipleValuesException

def main!
	fail 'Must run as root' unless Process.euid == 0
	$verbose = ARGV.include? '--verbose'
	Dir.chdir Pathname(__FILE__).dirname
	tasks = {
		"Checking for dependencies" => ->{
			commands = %w{ git wget tar }
			commands.each do |cmd|
				next if does_command_exist? cmd
				puts "We require the '%s' command. Install it using your package manager." % cmd; raise
			end
			puts "  Done"
		},
		"Determining system bittedness" => ->{
			raise "uname pattern match fail" unless execute("uname -a") =~ /\b(i686|x86_64)\b/
			$bittedness = $1
			$is64bit = $bittedness == 'x86_64'
			puts "  #{$is64bit ? "64" : "32"}-bit system"
		},
		"Downloading latest Crystal binary" => ->{
			puts "  Loading webpage" if $verbose
			html = openurl("https://github.com/crystal-lang/crystal/releases")
			puts "  Parsing html" if $verbose
			html = Nokogiri::HTML(html)
			puts "  Scanning html" if $verbose
			href = "https://github.com" + (html/"ul[class='release-downloads']/li/a").select { |a| (a/"strong").inner_text =~ /crystal-(.*)-linux-#{$bittedness}.tar.gz/ }.first[:href]
			raise "Could not find latest Crystal release on github" unless href
			puts "  Found Crystal release: " + href if $verbose
			puts "  Downloading archive" if $verbose
			Dir.chdir $tempdir do
				execute %{wget "#{href}" -O - | tar zx}
			end
		},
		"Installing Crystal dependency to /opt/cr-ox/" => ->{
			mkdir_p '/opt'
			rm_rf '/opt/cr-ox'
			Dir.chdir $tempdir do
				mv Dir.glob("crystal-*").single, '/opt/cr-ox'
			end
			mv *%w{ /opt/cr-ox/bin/crystal /opt/cr-ox/bin/cr-ox }
			ln_sf *%w{ /opt/cr-ox/bin/cr-ox /usr/local/bin/cr-ox }
			puts "  Done"
		},
		"Compiling Onyx in %d-bit release mode" % ($is64bit ? 64 : 32) => ->{
			mkdir_p '.build'
			#execute %{CRYSTAL_CONFIG_PATH=#{Dir.pwd}/src /opt/cr-ox/bin/cr-ox build --release --verbose --link-flags "-L/opt/cr-ox/embedded/lib" -o .build/onyx src/compiler/onyx.cr}
			execute "make all"
			execute "make install"
			puts "  Done"
		},
		"Installing Onyx" => ->{
			rm_rf '/opt/onyx'
			mkdir_p '/opt/onyx/bin'
			cp_r *%w{ /opt/cr-ox/embedded/ /opt/onyx/ }
			cp_r *%w{ src /opt/onyx/ }
			cp_r *%w{ .build/onyx /opt/onyx/embedded/bin/onyx }

			script = %{
				#!/usr/bin/env bash
				INSTALL_DIR="$(dirname $(readlink $0 || echo $0))/.."
				export CRYSTAL_PATH=${CRYSTAL_PATH:-"libs:$INSTALL_DIR/src"}
				export PATH="$INSTALL_DIR/embedded/bin:$PATH"
				export LIBRARY_PATH="$INSTALL_DIR/embedded/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"
				"$INSTALL_DIR/embedded/bin/onyx" "$@"
			}
			File.write '/opt/onyx/bin/onyx', script, mode: ?w

			FileUtils.chmod 0755, '/opt/onyx/bin/onyx'
			ln_sf *%w{ /opt/onyx/bin/onyx /usr/local/bin/onyx }
			puts "  Done"
		}
	}
	begin
		$tempdir = Pathname(Dir.mktmpdir)
		puts
		tasks.each do |name, task|
			begin
	 			puts ">> " + name
				task.()
			ensure
				print ?\n
			end
		end
		puts "SUCCESS!"
	rescue StandardError => e
		puts "***EXCEPTION: " + e.summarise, e.backtrace.map { |line| "  " + line }, "", "== PROCESS FAILED =="
		puts "Please create an issue at https://github.com/ozra/onyx-lang/issues"
		abort
	ensure
		FileUtils.rmdir $tempdir if Dir.exist? $tempdir
	end
end

def does_command_exist?(command)
	`which #{command}` !~ /(?:^$|not found)/
end
def execute(cmd)
	puts "  > " + cmd if $verbose
	output = `#{cmd}`
	unless $?.exitstatus == 0
		puts "", output, ""
		raise "%s exited with code %s" % [cmd, $?.exitstatus]
	end
	output
end
def openurl(domain, path = nil)
	url = path ? CombineURL(domain, path) : domain
	attempts = 0
	begin
		puts "  Opening " + url if $verbose
		url = URI.encode(url) if url.include? ' '
		result = Kernel.open(url, ?r).read
	rescue OpenURI::HTTPError, StandardError => e
		attempts += 1
		if attempts <= 10
			sleep 1
			retry
		end
		raise OpenURI::HTTPError.new(e.message + ' url=' + url, e.io) if e.is_a?(OpenURI::HTTPError)
	end
	result
end
def mkdir_p(dir)
	puts "  Ensuring directory #{dir} exists" if $verbose
	FileUtils.mkdir_p dir
end
def rm_rf(file)
	puts "  Removing " + file if $verbose
	FileUtils.rm_rf file
end
def mv(old, new)
	puts "  Moving #{old} to #{new}" if $verbose
	FileUtils.mv old, new
end
def cp_r(old, new)
	puts "  Copying #{old} to #{new}" if $verbose
	FileUtils.cp_r old, new, preserve: true
end
def ln_sf(old, new)
	puts "  Creating softlink #{old} => #{new}" if $verbose
	FileUtils.ln_sf old, new
end

main!
