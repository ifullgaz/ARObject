#
# Be sure to run `pod lib lint ARObject.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ARObject'
  s.version          = '0.6.0'
  s.summary          = 'A library to help develop AR apps.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
A library to help develop AR apps easily.
                       DESC

  s.homepage         = 'https://github.com/ifullgaz/ARObject'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Emmanuel Merali' => 'emmanuel@merali.me' }
  s.source           = { :git => 'https://github.com/ifullgaz/ARObject.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'
  s.swift_versions = ['5.0', '5.1']

  s.source_files = 'ARObject/Classes/**/*'
  
  # s.resource_bundles = {
  #   'ARObject' => ['ARObject/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'ARFocusSquare', '~> 2'
end
