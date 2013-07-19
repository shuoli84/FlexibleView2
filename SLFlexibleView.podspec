Pod::Spec.new do |s|
  s.name         = "SLFlexibleView"
  s.version      = "0.0.2"
  s.summary      = "Create and layout view in declarative way"
  s.homepage     = "https://github.com/shuoli84/FlexibleView2/"
  s.license      = 'MIT (example)'

  s.author       = { "shuo li" => "shuoli84@gmail.com" }
  s.source       = { :git => "https://github.com/shuoli84/FlexibleView2.git", :tag => "0.0.2" }

  s.platform     = :ios, '5.0'

  s.source_files = 'FlexibleView2/FVDeclaration.{h,m}'
  s.exclude_files = 'Classes/Exclude'

  s.requires_arc = true
end
