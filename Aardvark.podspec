Pod::Spec.new do |s|
  s.name     = 'Aardvark'
  s.version  = '3.4.4'
  s.license  = 'Apache License, Version 2.0'
  s.summary  = 'Aardvark is a library that makes it dead simple to create actionable bug reports.'
  s.homepage = 'https://github.com/square/Aardvark'
  s.authors  = 'Square'
  s.source   = { :git => 'https://github.com/square/Aardvark.git', :tag => "Aardvark/#{ s.version.to_s }" }

  s.swift_version = '4.0'
  s.ios.deployment_target = '8.0'

  s.source_files = 'Sources/Aardvark/**/*.{h,m,swift}'
  s.private_header_files = 'Sources/Aardvark/**/*_Testing.h', 'Sources/Aardvark/Private Categories/*.h'

  s.dependency 'CoreAardvark', '~> 2.0'
end
