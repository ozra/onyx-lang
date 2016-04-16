#!/usr/bin/env ruby
# apt-get update; apt-get install git ruby; git clone https://github.com/ozra/onyx-lang.git; cd onyx-lang; chmod 777 . -R

# TODO: Support rpm and pacman

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
require 'tmpdir'
optional_require 'pry'

DPKG_AND_APT_GET = "dpkg and apt-get"

def execute(cmd, error_echo = true)
	puts "  > " + cmd #if $verbose
	output = `#{cmd}`
	unless $?.exitstatus == 0
		puts "", output, "" if error_echo || $verbose
		raise "%s exited with code %s" % [cmd, $?.exitstatus]
	end
	output
end

module Kernel
	def require_gem(gem, auto_install = false)
		return if optional_require(gem)
		if auto_install
			puts "  Installing %s gem" % gem
			result = execute %{gem install "%s"} % gem
			Gem.clear_paths
			require_gem(gem, false)
		else
			fail "Requires %s gem" % gem
		end
	end
end

class Exception
	@shortform = nil
	def shortform; @shortform || self.class.name; end
	def summarise; "%s (%s)" % [message, self.class.name]; end
end
module Enumerable
	def single?
    self.one? ? self.first : nil
  end
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
	def first_match(pattern)
		map { |value| $~ if value =~ pattern }.compact.first
	end
end
def define_exceptions(*names)
	names.each { |name|
		raise "Exception '%s' is already defined" % name if Object.const_defined? name
		Object.const_set name.to_s, Class.new(StandardError)
	}
end
define_exceptions :NoValuesException, :MultipleValuesException, :GracefulFailure

def main!
	fail 'Must run as root' unless Process.euid == 0
	$verbose = ARGV.include? '--verbose'
	Dir.chdir Pathname(__FILE__).dirname
	tasks = []
	# tasks << ["Checking for dependencies", ->{
	# 	commands = %w{ git wget tar apt-cache }
	# 	commands.each do |cmd|
	# 		next if does_command_exist? cmd
	# 		puts "We require the '%s' command. Install it using your package manager." % cmd; raise
	# 	end
	# 	puts "  Done"
	# }]
	tasks << ["Determining system bittedness", ->{
		raise "uname pattern match fail" unless execute("uname -a") =~ /\b(i686|x86_64)\b/
		$bittedness = $1
		$is64bit = $bittedness == 'x86_64'
		puts "  #{$is64bit ? "64" : "32"}-bit system"
	}]
	tasks << ["Checking for sufficient memory", ->{
		ram = get_total_ram.to_f / (1024 * 1024 * 1024)
		swap = get_total_swap.to_f / (1024 * 1024 * 1024)
		puts "  Found %.2fGB RAM and %.2fGB swap" % [ram, swap]
		if ram + swap < 1.9		# When is a gig not a gig? When a graphics card is stealing some of it!
			puts "  Failed"
			raise GracefulFailure, "Requires at least 2GB memory or swap"
		end
	}]
	tasks << ["Checking for compatible package manager", ->{
		$package_manager = case
			when does_command_exist?("dpkg") && does_command_exist?("apt-get")
				DPKG_AND_APT_GET
			else
				nil
		end
		puts $package_manager ? "  Found #{$package_manager}" : "  Didn't find one"
	}]
	tasks << ["Checking for dependencies", ->{
		commands = %w{ git wget tar pkg-config curl }
		commands << "apt-cache" if $package_manager == DPKG_AND_APT_GET
		missing_commands = commands.reject { |cmd| does_command_exist? cmd }
		if missing_commands.some?
			if $package_manager
				missing_commands.reverse.each { |cmd| tasks.unshift ["Installing #{cmd}", ->{ install_package cmd; puts "  Done" }] }
			else
				raise GracefulFailure, "  Could not find the following commands. You must install them yourself.\n" + missing_commands.map { |cmd| "    " + cmd }.join(?\n)
			end
		end
		missing_packages = %w{
			llvm-3.5-dev libpcre3-dev build-essential zlib1g-dev automake libtool libedit-dev libssl-dev libevent-dev libgc-dev libreadline-dev libgdbm-dev ruby-dev
		}.reject { |pkg| is_package_installed? pkg }
		if missing_packages.some?
			if $package_manager
				missing_packages.reverse.each { |pkg|
					tasks.unshift ["Installing #{pkg}", ->{ install_package pkg; puts "  Done" }]
				}
			else
				puts "  Assuming the following packages exist, as we have no way to verify this:\n    " + missing_packages.join(', ')
				return
			end
		end
		puts "  Done"
	}]
	tasks << ["Downloading latest Crystal binary", ->{
		require_gem 'nokogiri', true
		puts "  Loading webpage" if $verbose
		html = openurl "https://github.com/crystal-lang/crystal/releases"
		puts "  Parsing html" if $verbose
		html = Nokogiri::HTML(html)
		puts "  Scanning html" if $verbose
		href = "https://github.com" + (html/"ul[class='release-downloads']/li/a").select { |a| (a/"strong").inner_text =~ /crystal-(.*)-linux-#{$bittedness}.tar.gz/ }.first[:href]
		raise "Could not find latest Crystal release on github" unless href
		puts "  Found Crystal release: " + href if $verbose
		puts "  Downloading archive" if $verbose
		Dir.chdir $tempdir do
			execute %{wget#{' -q' unless $verbose} "#{href}" -O - | tar zx}
		end
	}]
	tasks << ["Checking if Crystal works", ->{
		begin
			crystal = (Pathname(Dir.glob($tempdir + 'crystal-*')[0]) + 'bin/crystal').to_s
			execute "echo 'puts' | #{crystal} >/dev/null 2>/dev/null eval", false
			puts "  Yes it does. Will wonders never cease?"
		rescue
			puts "  Of course not. That would be too easy."
			tasks.unshift ["Installing Crystal prerequisites", ->{
				workingdir = Pathname(Dir.mktmpdir "crystal-env")
				begin
					Dir.chdir workingdir do
						puts "  Created temporary directory: #{workingdir}" if $verbose
						# $logger << "Current directory is ⟨W%s⟩. Contents: %s" % [Dir.current, Dir.entries(Dir.current).wrap("⟨W", "⟩").join(", ")]
						puts $verbose ? "  Downloading bdwgc" : "  Downloading and compiling bdwgc"
						execute "git clone git://github.com/ivmai/bdwgc.git"
						puts "  Compiling bdwgc" if $verbose
						Dir.chdir "bdwgc" do
							execute "git clone git://github.com/ivmai/libatomic_ops.git"
							execute "autoreconf -vif"
							execute "automake --add-missing"
							execute "./configure"
							execute "make"
							execute "make install"
						end

						puts "", $verbose ? "  Downloading pcl" : "  Downloading and compiling pcl"
						execute "curl -O#{' -s' unless $verbose} http://www.xmailserver.org/pcl-1.12.tar.gz"
						execute "tar -xzf pcl-1.12.tar.gz"
						puts "  Compiling pcl" if $verbose
						Dir.chdir "pcl-1.12" do
							execute "./configure"
							execute "make"
							execute "make install"
						end
						puts ""
						puts "  Deleting old versions" if $verbose
						rm_f "/usr/lib/libgc.so*"
						begin
							uninstall_package("libpcl1-dev") if is_package_installed? "libpcl1-dev"
						rescue
							puts "  Failed to uninstall package: libpcl1-dev\n  You must remove it yourself if it is installed."
						end
					end
				ensure
					rm_rf workingdir if Dir.exist? workingdir
				end
			}]
		end
	}]
	tasks << ["Installing Crystal dependency to /opt/cr-ox/", ->{
		mkdir_p '/opt'
		rm_rf '/opt/cr-ox'
		Dir.chdir $tempdir do
			mv Dir.glob("crystal-*").single, '/opt/cr-ox'
		end
		mv *%w{ /opt/cr-ox/bin/crystal /opt/cr-ox/bin/cr-ox }
		ln_sf *%w{ /opt/cr-ox/bin/cr-ox /usr/local/bin/cr-ox }
		puts "  Done"
	}]
	tasks << ["Compiling Onyx in %d-bit release mode" % ($is64bit ? 64 : 32), ->{
		mkdir_p '.build'
		#execute %{CRYSTAL_CONFIG_PATH=#{Dir.pwd}/src /opt/cr-ox/bin/cr-ox build --release --verbose --link-flags "-L/opt/cr-ox/embedded/lib" -o .build/onyx src/compiler/onyx.cr}
		execute "make all"
		execute "make install"
		puts "  Done"
	}]
	# tasks << ["Installing Onyx", ->{
	# 	rm_rf '/opt/onyx'
	# 	mkdir_p '/opt/onyx/bin'
	# 	cp_r *%w{ /opt/cr-ox/embedded/ /opt/onyx/ }
	# 	cp_r *%w{ src /opt/onyx/ }
	# 	cp_r *%w{ .build/onyx /opt/onyx/embedded/bin/onyx }
	#
	# 	script = %{
	# 		#!/usr/bin/env bash
	# 		INSTALL_DIR="$(dirname $(readlink $0 || echo $0))/.."
	# 		export CRYSTAL_PATH=${CRYSTAL_PATH:-"libs:$INSTALL_DIR/src"}
	# 		export PATH="$INSTALL_DIR/embedded/bin:$PATH"
	# 		export LIBRARY_PATH="$INSTALL_DIR/embedded/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"
	# 		"$INSTALL_DIR/embedded/bin/onyx" "$@"
	# 	}
	# 	File.write '/opt/onyx/bin/onyx', script, mode: ?w
	#
	# 	chmod 0755, '/opt/onyx/bin/onyx'
	# 	ln_sf *%w{ /opt/onyx/bin/onyx /usr/local/bin/onyx }
	# 	puts "  Done"
	# }]
	tasks << ["Checking if Onyx works", ->{
		begin
			execute "echo 'say' | onyx", false
			puts "  Yes it does. Hooray!"
		rescue
			puts "  Nope, still buggered.", "", "== PROCESS FAILED =="
			puts "Please create an issue at https://github.com/ozra/onyx-lang/issues, and include this output."
 			raise GracefulFailure
		end
	}]
	begin
		$tempdir = Pathname(Dir.mktmpdir)
		puts
		while tasks.some?
			name, task = tasks.shift
			begin
	 			puts ">> %s..." % name
				task.()
			ensure
				print ?\n
			end
		end
		puts "SUCCESS!"
	rescue GracefulFailure => e
		puts e.message, ""
		abort
	rescue StandardError => e
		puts "***EXCEPTION: " + e.summarise, e.backtrace.map { |line| "  " + line }, "", "== PROCESS FAILED =="
		puts "Please create an issue at https://github.com/ozra/onyx-lang/issues, and include this output."
		abort
	ensure
		rm_rf $tempdir if Dir.exist? $tempdir
	end
end

def get_total_ram
	lines = File.readlines("/proc/meminfo").map &:chomp
	kb = lines.first_match(/^MemTotal:\s+(\d+)\s+kB$/)[1].to_i
	kb ? kb * 1024 : 0
end
def get_total_swap
	lines = File.readlines("/proc/meminfo").map &:chomp
	kb = lines.first_match(/^SwapTotal:\s+(\d+)\s+kB$/)[1].to_i
	kb ? kb * 1024 : 0
end
def get_linux_distro
	return nil unless File.file? "/etc/os-release"
	content = File.readlines("/etc/os-release").map &:chomp
	distro = content.first_match(/^ID=(.*)/)[1]
	version = content.first_match(/^VERSION_ID="(.*)"/)[1]
	{distro: distro, version: version} if distro
end
def is_linux_distro?(distro, version = nil)
	result = get_linux_distro
	return false unless result && result[:distro] && result[:distro].downcase == distro.downcase
	return false if version && result[:version] != version.to_s
	return true
end
def is_package_installed?(pkg)
	case $package_manager
		when DPKG_AND_APT_GET
			execute("dpkg-query -W -f='${status}' '#{pkg}' 2>&1 || true").split(?\s).include?("installed")
		else
			raise GracefulFailure, "Could not find a supported package manager"
	end
end
def is_package_known?(package)
	case $package_manager
		when DPKG_AND_APT_GET
			# unless $apt_cache_is_updated
			# 	execute "apt-cache update"
			# 	$apt_cache_is_updated = true
			# end
			`apt-cache search ^#{package}$`.split("\n").reject { |line| line == "" }.any?
	end
end
def add_apt_lines(lines)
	file = "/etc/apt/sources.list"
	raise "Could not find file: %s" % file unless File.file? file
	existing_lines = File.readlines(file).map(&:chomp)
	return if lines.all? { |line| existing_lines.map(&:strip).include? line }
	File.write file, (existing_lines + lines).join(?\n)
end
def install_package(package, force = false)
	if package == "llvm-3.5-dev" && !is_package_known?("llvm-3.5-dev") && $package_manager == DPKG_AND_APT_GET && is_linux_distro?("Debian", 7)
		puts "  Adding apt source lines for llvm-3.5-dev" if $verbose
		add_apt_lines %{
			deb http://llvm.org/apt/wheezy/ llvm-toolchain-wheezy main
			deb-src http://llvm.org/apt/wheezy/ llvm-toolchain-wheezy main
		}.split(?\n).map &:strip
		execute "apt-get update"
	end
	raise "Package %s cannot be found" % package unless is_package_known? package
	return if is_package_installed? package
	case $package_manager
		when DPKG_AND_APT_GET
			cmd = %{apt-get install -y "#{package}"}
			force = true if package == "llvm-3.5-dev"
			cmd << " --force-yes" if force
			execute cmd
		else
			raise "Cannot install '#{package}'. No supported package manager found."
	end
end
def uninstall_package(package)
	execute %{apt-get remove "#{package}"}
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
def rm_f(file)
	puts "  Removing " + file if $verbose
	FileUtils.rm_f file
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
def chmod(mode, file)
	puts "  Changing permissions of #{file} to #{mode}" if $verbose
	FileUtils.chmod mode, file
end
def does_command_exist?(command)
	`which #{command}` !~ /(?:^$|not found)/
end

main!
