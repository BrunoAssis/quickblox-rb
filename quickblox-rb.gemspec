Gem::Specification.new do |s|
  s.name = "quickblox-rb"
  s.version = "0.1.0"
  s.summary = "Ruby gem to work with Quickblox API"
  s.description = s.summary
  s.authors = ["Lucas Tolchinsky"]
  s.email = ["lucas.tolchinsky@gmail.com"]
  s.homepage = "https://github.com/properati/quickblox-rb"
  s.license = "MIT"

  s.files = `git ls-files`.split("\n")

  s.add_runtime_dependency "requests"

  s.add_development_dependency "cutest"
  s.add_development_dependency "mocoso"
end

