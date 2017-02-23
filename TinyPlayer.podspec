#
# Be sure to run `pod lib lint TinyPlayer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TinyPlayer'
  s.version          = '0.9.1'
  s.summary          = 'TinyPlayer is simple, elegant and highly efficient video player for iOS
  and tvOS. It is based on Apple’s AVFoundation framework. '

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Served as the core player component of our Quazer[] app, we spent a lot of effort to build it up by
following the industrial best practises in terms of maximal utilizing Apple’s AVFoundation framework.
AVFoundation is powerful but unfortunately not easy to use. To unleash the most potential of it, an
experienced developer will also spend quiet amount of time to set up everything correctly.
We alleviate the burden of you by providing a easy-to-use player component which encapsulates all
the complexities within.
                       DESC

  s.homepage         = 'https://github.com/xiaohu557/TinyPlayer'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xiaohu557' => 'kevinchen@me.com' }
  s.source           = { :git => 'https://github.com/xiaohu557/TinyPlayer.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.1'
  s.tvos.deployment_target = '9.1'

  s.source_files = 'Sources/Classes/**/*'

  s.resource_bundles = {
     'TinyPlayer' => ['Sources/Assets/*.*']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
