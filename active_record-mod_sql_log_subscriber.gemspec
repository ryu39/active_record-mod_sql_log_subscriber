lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_record/mod_sql_log_subscriber"

Gem::Specification.new do |spec|
  spec.name          = "active_record-mod_sql_log_subscriber"
  spec.version       = ActiveRecord::ModSqlLogSubscriber::VERSION
  spec.authors       = ["ryu39"]
  spec.email         = ["dev.ryu39@gmail.com"]

  spec.summary       = %q{An ActiveRecord::LogSubscriber which records only mod sql.}
  spec.description   = %q{An ActiveRecord::LogSubscriber which records only mod sql.}
  spec.homepage      = "https://github.com/ryu39/active_record-mod_sql_log_subscriber"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(config|db|test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport", '>= 5.1.5'
  spec.add_runtime_dependency "activerecord", '>= 5.1.5'

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "sqlite3", "~> 1.3.6"
end
