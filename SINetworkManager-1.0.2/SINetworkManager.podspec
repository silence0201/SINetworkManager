Pod::Spec.new do |s|
  s.name = "SINetworkManager"
  s.version = "1.0.2"
  s.summary = "A NetworkManager With AFNetworking And YYCache."
  s.license = {"type"=>"MIT", "file"=>"LICENSE"}
  s.authors = {"Silence"=>"374619540@qq.com"}
  s.homepage = "https://github.com/silence0201/SINetworkManager"
  s.description = "A Network Manager With AFNetworking And YYCache"
  s.requires_arc = true
  s.source = { :path => '.' }

  s.ios.deployment_target    = '7.0'
  s.ios.vendored_framework   = 'ios/SINetworkManager.framework'
end
