Pod::Spec.new do |s|
  s.name     = 'Aardvark'
  s.version  = '1.0.2'
  s.license  = 'Apache License, Version 2.0'
  s.summary  = 'Aardvark is a library that makes it dead simple to create actionable bug reports.'
  s.homepage = 'https://github.com/square/Aardvark'
  s.authors  = 'Square'
  s.source   = { :git => 'https://github.com/square/Aardvark.git', :tag => s.version }
  s.source_files = 'Aardvark/*.{h,m}', 'Categories/*.{h,m}', 'Other/*.{h,m}', 'Logging/*.{h,m}', 'Log Viewing/*.{h,m}', 'Bug Reporting/*.{h,m}'
  s.private_header_files = 'Categories/*.h', '**/*_Testing.h'
  s.ios.deployment_target = '6.0'
end
