Gem::Specification.new do |s|
  s.name    = 'adyen'
  s.version = "0.3.8.20100929"
  s.date    = "2010-09-29"

  s.summary = "Integrate Adyen payment services in your Ruby on Rails application."
  s.description = <<-EOS
    Package to simplify including the Adyen payments services into a Ruby on Rails application.
    The package provides functionality to create payment forms, handling and storing notifications 
    sent by Adyen and consuming the SOAP services provided by Adyen. Moreover, it contains helper
    methods, mocks and matchers to simpify writing tests/specsfor your code.
  EOS

  s.authors  = ['Willem van Bergen', 'Michel Barbosa', 'Stefan Borsje', 'Eloy Duran']
  s.email    = ['willem@vanbergen.org', 'cicaboo@gmail.com', 'mail@sborsje.nl', 'eloy.de.enige@gmail.com']
  s.homepage = 'http://github.com/wvanbergen/adyen/wiki'

  s.add_development_dependency('rake')
  s.add_development_dependency('rspec', '~> 2.0')
  s.add_development_dependency('nokogiri')
  s.add_development_dependency('rails', '>= 2.3')
  
  s.requirements << 'Having Nokogiri installed will speed up XML handling when using the SOAP API.'

  s.rdoc_options << '--title' << s.name << '--main' << 'README.rdoc' << '--line-numbers' << '--inline-source'
  s.extra_rdoc_files = ['README.rdoc']

  s.files = %w(spec/spec_helper.rb spec/adyen_spec.rb lib/adyen/form.rb .gitignore spec/notification_spec.rb lib/adyen/api.rb LICENSE spec/api_spec.rb init.rb adyen.gemspec Rakefile spec/form_spec.rb README.rdoc lib/adyen/notification.rb lib/adyen/formatter.rb tasks/github-gem.rake lib/adyen/encoding.rb TODO lib/adyen/matchers.rb lib/adyen.rb)
  s.test_files = %w(spec/adyen_spec.rb spec/notification_spec.rb spec/api_spec.rb spec/form_spec.rb)
end
