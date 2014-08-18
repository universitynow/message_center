lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'message_center/version'

Gem::Specification.new do |s|
  s.name = "message_center"
  s.version = MessageCenter::VERSION

  s.authors = ["Eduardo Casanova Cuesta","Ariel Fox","Dave Gynn"]
  s.summary = "Messaging system for rails apps."
  s.description = "A Rails engine that provides Conversations with Messages, Mailboxes for organizing Conversations, and Notifications for system messages"
  s.email = "developers@unow.com"
  s.homepage = "https://github.com/university_now/message_center"
  s.files = `git ls-files`.split("\n")
  s.license = 'MIT'

  # Gem dependencies
  s.add_runtime_dependency('rails', '>= 4.0.0')
  s.add_runtime_dependency('pg', '>= 0.17.1')
  s.add_runtime_dependency('hooks', '>= 0.4.0')

  # Optional dependencies
  s.add_development_dependency('carrierwave', '>= 0.5.8')

  # Specs
  s.add_development_dependency('rspec-rails')
  s.add_development_dependency('appraisal', '~> 1.0.0')
  s.add_development_dependency('shoulda-matchers')
  # Fixtures
  s.add_development_dependency('factory_girl', '~> 2.6.0')
  # Population
  s.add_development_dependency('forgery', '>= 0.3.6')
  # Integration testing
  s.add_development_dependency('capybara', '>= 0.3.9')

end
