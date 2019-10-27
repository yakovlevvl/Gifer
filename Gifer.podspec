
Pod::Spec.new do |spec|

spec.name          = "Gifer"
spec.version       = "1.0.2"
spec.summary       = "Framework for converting videos to high-quality GIFs."
spec.description   = "Framework for converting videos to high-quality GIFs on iOS."
spec.homepage      = "https://github.com/yakovlevvl/Gifer"
spec.license       = { :type => "MIT", :file => "LICENSE" }
spec.author        = { "Vladyslav Yakovlev" => "yakovlev15@icloud.com" }
spec.platform      = :ios, "10.0"
spec.source        = { :git => "https://github.com/yakovlevvl/Gifer.git", :tag => spec.version }
spec.source_files  = "Gifer/*.swift"
spec.swift_version = "5.0"

end
