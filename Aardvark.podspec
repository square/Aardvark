Pod::Spec.new do |s|
  s.name     = 'Aardvark'
  s.version  = '1.6.0'
  s.license  = 'Apache License, Version 2.0'
  s.summary  = 'Aardvark is a library that makes it dead simple to create actionable bug reports.'
  s.homepage = 'https://github.com/square/Aardvark'
  s.authors  = 'Square'
  s.source   = { :git => 'https://github.com/square/Aardvark.git', :tag => s.version }
  s.ios.deployment_target = '6.0'
  s.default_subspec = 'Aardvark'
  
  s.subspec 'Aardvark' do |a|
    a.source_files = 'Aardvark/*.{h,m}', 'Categories/*.{h,m}', 'Other/*.{h,m}', 'Logging/*.{h,m}', 'Log Viewing/*.{h,m}', 'Bug Reporting/*.{h,m}'
    a.private_header_files = 'Aardvark/*_Testing.h', 'Categories/*.h', 'Other/*_Testing.h', 'Logging/*_Testing.h', 'Log Viewing/*_Testing.h', 'Bug Reporting/*_Testing.h'
    a.dependency 'Aardvark/AardvarkCore'
  end

  s.subspec 'AardvarkCore' do |ac|
    ac.source_files = 'CoreAardvark/*.{h,m}', 'CoreCategories/*.{h,m}', 'CoreOther/*.{h,m}', 'CoreLogging/*.{h,m}'
    ac.private_header_files = 'CoreAardvark/*_Testing.h', 'CoreCategories/*.h', 'CoreOther/*_Testing.h', 'CoreLogging/*_Testing.h'
  end 
end
