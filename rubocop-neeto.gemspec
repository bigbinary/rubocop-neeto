# frozen_string_literal: true

require_relative "lib/rubocop/neeto/version"

Gem::Specification.new do |spec|
  spec.name = "rubocop-neeto"
  spec.version = RuboCop::Neeto::VERSION
  spec.authors = ["Abhay V Ashokan"]
  spec.email = ["abhay.ashokan@bigbinary.com"]

  spec.summary = "Custom RuboCop cops for Neeto"
  spec.homepage = "https://github.com/bigbinary/rubocop-neeto"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'rubocop'
end
