Pod::Spec.new do |s|
  s.name     = 'CoreAardvark'
  s.version  = '3.0.3'
  s.license  = 'Apache License, Version 2.0'
  s.summary  = 'Aardvark is a library that makes it dead simple to create actionable bug reports. Usable by extensions.'
  s.homepage = 'https://github.com/square/Aardvark'
  s.authors  = 'Square'
  s.source   = { :git => 'https://github.com/square/Aardvark.git', :tag => "CoreAardvark/#{ s.version.to_s }" }

  s.swift_version = '5.0'
  s.ios.deployment_target = '12.0'
  s.watchos.deployment_target = '4.0'

  s.source_files = 'Sources/CoreAardvark/**/*.{h,m,swift}'
  s.private_header_files = 'Sources/CoreAardvark/**/*_Testing.h', 'Sources/CoreAardvark/PrivateCategories/*.h'
end
