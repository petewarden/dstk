Gem::Specification.new do |s|
  s.name        = 'dstk'
  s.version     = '0.50.1'
  s.date        = '2013-05-14'
  s.summary     = "Data Science Toolkit client"
  s.description = "An interface to the datasciencetoolkit.org open API for geocoding addresses, extracting entities and sentiment from unstructured text, and other common semantic and geo data tasks."
  s.authors     = ["Pete Warden"]
  s.email       = 'pete@petewarden.com'
  s.files       = ["lib/dstk.rb"]
  s.homepage    = 'http://rubygems.org/gems/dstk'
  s.add_dependency 'json'
  s.add_dependency 'httparty'
  s.add_dependency 'httmultiparty'
end

