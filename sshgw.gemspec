# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "sshgw/version"

Gem::Specification.new do |s|
  s.name        = "sshgw"
  s.version     = Sshgw::VERSION
  s.authors     = ["Jacques-Daniel PILLON"]
  s.email       = ["jdpillon@lesalternatives.org"]
  s.homepage    = ""
  s.summary     = %q{Configure an sshgw to multiple serers behind an unique ip}
  s.description = s.summary

  #s.rubyforge_project = "sshgw"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "net-ssh-gateway"
  s.add_runtime_dependency "net-scp"
  s.add_runtime_dependency "highline"
end
