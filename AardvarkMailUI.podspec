Pod::Spec.new do |s|
  s.name     = 'AardvarkMailUI'
  s.version  = '2.0.1'
  s.license  = 'Apache License, Version 2.0'
  s.summary  = 'Aardvark components for submitting a bug report via an email composer.'
  s.homepage = 'https://github.com/square/Aardvark'
  s.authors  = 'Square'
  s.source   = { :git => 'https://github.com/square/Aardvark.git', :tag => "AardvarkMailUI/#{ s.version.to_s }" }

  s.swift_version = '5.0'
  s.ios.deployment_target = '14.0'

  s.source_files = 'Sources/AardvarkMailUI/**/*.{h,m,swift}'
  s.private_header_files = 'Sources/AardvarkMailUI/**/*_Testing.h', 'Sources/AardvarkMailUI/PrivateCategories/*.h'

  s.dependency 'Aardvark', '~> 5.0'
end
