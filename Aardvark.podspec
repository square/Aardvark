Pod::Spec.new do |s|
  s.name     = 'Aardvark'
  s.version  = '5.1.0'
  s.license  = 'Apache License, Version 2.0'
  s.summary  = 'Aardvark is a library that makes it dead simple to create actionable bug reports.'
  s.homepage = 'https://github.com/square/Aardvark'
  s.authors  = 'Square'
  s.source   = { :git => 'https://github.com/square/Aardvark.git', :tag => "Aardvark/#{ s.version.to_s }" }

  s.swift_version = '5.0'
  s.ios.deployment_target = '14.0'

  s.source_files = 'Sources/Aardvark/**/*.{h,m}', 'Sources/AardvarkSwift/**/*.{swift}'
  s.resource_bundle = {'Aardvark' => ['Sources/Aardvark/PrivacyInfo.xcprivacy']}

  s.dependency 'CoreAardvark', '~> 4.0'
end
