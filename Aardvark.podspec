Pod::Spec.new do |s|
  s.name     = 'Aardvark'
  s.version  = '1.0.0'
  s.license  = 'Apache'
  s.summary  = 'Aardvark is a library that makes it dead simple to create actionable bug reports.'
  s.homepage = 'https://stash.corp.squareup.com/projects/IOS/repos/aardvark/browse'
  s.authors  = { 'Dan Federman' => 'federman@squareup.com' }
  s.source   = { :git => 'https://stash.corp.squareup.com/scm/ios/aardvark.git', :tag => s.version }
  s.source_files = 'Aardvark/*.{h,m}', 'Categories/*.{h,m}', 'Other/*.{h,m}', 'Logging/*.{h,m}', 'Log Viewing/*.{h,m}', 'Bug Reporting/*.{h,m}'
  s.private_header_files = 'Categories/*.h', '**/*_Testing.h'
  s.prefix_header_file = 'Other/Aardvark-Prefix.pch'
  s.ios.deployment_target = '6.0'
end
