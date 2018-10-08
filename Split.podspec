Pod::Spec.new do |s|
  s.name             = 'Split'
  s.module_name      = 'Split'
  s.version          = '1.5.1'
  s.summary          = 'iOS SDK for Split'

  s.description      = <<-DESC
This SDK is designed to work with Split, the platform for controlled rollouts, serving features to your users via the Split feature flag to manage your complete customer experience.
                       DESC

  s.homepage         = 'http://www.split.io'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Patricio Echague' => 'pato@split.io', 'Sebastian Arrubia' => 'sebastian@split.io', 'Fernando Martin' => 'fernando@split.io'}
  s.source = { :git => 'https://github.com/splitio/ios-client.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.source_files = 'Split/**/*'
  s.frameworks = 'Foundation'
  s.source_files = 'Split/*.{swift}'
  s.source_files = 'Split/**/*.{swift}'

end
