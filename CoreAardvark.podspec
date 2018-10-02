Pod::Spec.new do |s|
  s.name     = 'CoreAardvark'
  s.version  = '2.2.0'
  s.license  = 'Apache License, Version 2.0'
  s.summary  = 'Aardvark is a library that makes it dead simple to create actionable bug reports. Usable by extensions.'
  s.homepage = 'https://github.com/square/Aardvark'
  s.authors  = 'Square'
  s.source   = { :git => 'https://github.com/square/Aardvark.git', :tag => "CoreAardvark/#{ s.version.to_s }" }
  s.ios.deployment_target = '8.0'
  s.watchos.deployment_target = '3.0'
  s.source_files = 'CoreAardvark/**/*.{h,m,swift}'
  s.private_header_files = 'CoreAardvark/*_Testing.h', 'CoreAardvark/Private Categories/*.h'
end
