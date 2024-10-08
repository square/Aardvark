Pod::Spec.new do |s|
  s.name     = 'AardvarkLoggingUI'
  s.version  = '2.0.0'
  s.license  = 'Apache License, Version 2.0'
  s.summary  = 'Aardvark components for viewing logs inside of an iOS app.'
  s.homepage = 'https://github.com/square/Aardvark'
  s.authors  = 'Square'
  s.source   = { :git => 'https://github.com/square/Aardvark.git', :tag => "AardvarkLoggingUI/#{ s.version.to_s }" }

  s.swift_version = '5.0'
  s.ios.deployment_target = '14.0'

  s.source_files = 'Sources/AardvarkLoggingUI/**/*.{h,m}'
  s.private_header_files = 'Sources/AardvarkLoggingUI/**/*_Testing.h', 'Sources/AardvarkLoggingUI/PrivateCategories/*.h'

  s.dependency 'CoreAardvark', '~> 4.0'
end
