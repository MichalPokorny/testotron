Gem::Specification.new do |s|
	s.name = 'testotron'
	s.version = '0.0.7'
	s.date = '2013-02-16'
	s.summary = 'Simple server testing'
	s.description = <<-EOF
		Testotron can automatically test basic functions of common servers, so you
		can get an alert when some piece of your configuration stops working.
EOF
	s.authors = [ "Michal Pokorny" ]
	s.email = "pok@rny.cz"
	s.files = Dir["lib/**/*.rb"]
	s.homepage = "http://github.com/MichalPokorny/testotron"

	# For SMTP testing
	s.add_runtime_dependency 'mail'
end
