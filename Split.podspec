Pod::Spec.new do |s|
  s.name             = 'Split'
  s.module_name             = 'Split'
  s.version          = '0.1.0'
  s.summary          = 'iOS SDK for Split'

  s.description      = <<-DESC
This SDK is designed to work with Split, the platform for controlled rollouts, serving features to your users via the Split feature flag to manage your complete customer experience.
                       DESC

s.homepage         = 'http://www.split.io'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Patricio Echague' => 'pato@split.io', 'Sebastian Arrubia' => 'sebastian@split.io', 'Nicolás Zelaya' => 'nicolas.zelaya@split.io', 'Brian Sztamfater' => 'bsztamfater@makingsense.com' }
  s.source           = { :git => 'https://github.com/splitio/ios-client', :tag => s.version.to_s }
  s.ios.deployment_target = '11.0'
#s.osx.deployment_target = '10.10'
#s.watchos.deployment_target = '2.0'
#s.tvos.deployment_target = '11.0'
  s.source_files = 'Split/**/*'
  s.frameworks = 'Foundation'
  s.dependency 'Alamofire', '4.5'
  s.dependency 'SwiftyJSON', '3.1.4'
  s.source_files = 'Split/*.{swift}'
  s.source_files = 'Split/**/*.{swift}'

#s.subspec 'Domain' do |ss|
#    ss.source_files = 'Split/Domain/*'
#    ss.source_files = 'Split/Domain/**/*.{swift}'
#  end

#  s.subspec 'Networking' do |ss|
#    ss.source_files = 'Split/Networking/*'
#    ss.source_files = 'Split/Networking/**/*.{swift}'
#  end

#  s.subspec 'Extensions' do |ss|
#    ss.source_files = 'Split/Extensions/*'
#  end

#  s.subspec 'Infrastructure' do |ss|
#    ss.dependency 'Split/Domain'
#    ss.dependency 'Split/Extensions'
#    ss.source_files = 'Split/Infrastructure/*'
#    ss.source_files = 'Split/Infrastructure/**/*.{swift}'
#  end

end
