#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'edge_detection'
  s.version          = '1.0.5'
  s.summary          = 'Plugin to detect edges of objects'
  s.description      = <<-DESC
Plugin to detect edges of objects
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.resources        = 'Assets/**/*'
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.subspec 'WeScan' do |ss|
    ss.source_files = 'WeScan/WeScan/**/*.{h,m,swift}'
    ss.resources = 'WeScan/WeScan/**/*.{strings,png}'
  end
  s.swift_version = '4.2'
  s.ios.deployment_target = '10.0'
end

