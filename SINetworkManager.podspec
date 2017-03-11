Pod::Spec.new do |s|
  s.name         = "SINetworkManager"
  s.version      = "1.0.1"
  s.summary      = "A NetworkManager With AFNetworking And YYCache."
  s.description  = <<-DESC
                      A Network Manager With AFNetworking And YYCache
                   DESC

  s.homepage     = "https://github.com/silence0201/SINetworkManager"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Silence" => "374619540@qq.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/silence0201/SINetworkManager.git", :tag => "1.0.1" }
  s.source_files  = "SINetworkManager", "SINetworkManager/**/*.{h,m}"
  s.exclude_files = "SINetworkManager/Exclude"
  s.public_header_files = "SINetworkManager/**/*.h"
  s.requires_arc = true
  s.dependency "AFNetworking", "~> 3.1"
  s.dependency "YYCache", "~> 1.0"

end
