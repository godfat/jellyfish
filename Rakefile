
begin
  require "#{__dir__}/task/gemgem"
rescue LoadError
  sh 'git submodule update --init --recursive'
  exec Gem.ruby, '-S', $PROGRAM_NAME, *ARGV
end

Gemgem.init(__dir__) do |s|
  require 'jellyfish/version'
  s.name    = 'jellyfish'
  s.version = Jellyfish::VERSION
  s.files.delete('jellyfish.png')
end
