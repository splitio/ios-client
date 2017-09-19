Pod::Spec.new do |s|
  s.name             = 'Split'
  s.version          = '0.1.0'
  s.summary          = 'iOS SDK for Split'

  s.description      = <<-DESC
This SDK is designed to work with Split, the platform for controlled rollouts, serving features to your users via the Split feature flag to manage your complete customer experience.
                       DESC

  s.homepage         = 'www.split.io'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Patricio Echague' => 'pato@split.io', 'Sebastian Arrubia' => 'sebastian@split.io', 'Nicolás Zelaya' => 'nicolas.zelaya@split.io', 'Brian Sztamfater' => 'bsztamfater@makingsense.com' }
  s.source           = { :git => 'https://github.com/splitio/ios-client', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'
  s.source_files = 'Split/**/*'
  s.frameworks = 'Foundation'
  s.source_files = 'Split/*.{swift}'
end
