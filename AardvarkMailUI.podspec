Pod::Spec.new do |s|
  s.name     = 'AardvarkMailUI'
  s.version  = '1.0.0'
  s.license  = 'Apache License, Version 2.0'
  s.summary  = 'Aardvark is a library that makes it dead simple to create actionable bug reports.'
  s.homepage = 'https://github.com/square/Aardvark'
  s.authors  = 'Square'
  s.source   = { :git => 'https://github.com/square/Aardvark.git', :tag => "AardvarkMailUI/#{ s.version.to_s }" }

  s.swift_version = '4.0'
  s.ios.deployment_target = '8.0'

  s.source_files = 'Sources/AardvarkMailUI/**/*.{h,m,swift}'
  s.private_header_files = 'Sources/AardvarkMailUI/**/*_Testing.h', 'Sources/AardvarkMailUI/Private Categories/*.h'

  s.dependency 'Aardvark', '~> 3.4'
end
