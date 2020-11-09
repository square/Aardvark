Pod::Spec.new do |s|
  s.name     = 'AardvarkReveal'
  s.version  = '1.0.0'
  s.license  = 'Apache License, Version 2.0'
  s.summary  = 'Aardvark components for generating a bug report attachment containing a Reveal file.'
  s.homepage = 'https://github.com/square/Aardvark'
  s.authors  = 'Square'
  s.source   = { :git => 'https://github.com/square/Aardvark.git', :tag => "AardvarkReveal/#{ s.version.to_s }" }

  s.swift_version = '4.0'
  s.ios.deployment_target = '8.0'

  s.source_files = 'Sources/AardvarkReveal/**/*.{h,m,swift}'

  s.dependency 'Aardvark', '~> 4.0'
end
