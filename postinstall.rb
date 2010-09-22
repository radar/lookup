require 'fileutils'
require 'pathname'
lookup = Pathname.new(ENV["HOME"]) + ".lookup"
FileUtils.mkdir_p(lookup)
FileUtils.cp(File.dirname(__FILE__) + "/config/lookup", lookup + "config")
