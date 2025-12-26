Pod::Spec.new do |s|
  s.name             = 'esim_manager'
  s.version          = '0.0.2'
  s.summary          = 'Flutter plugin for eSIM support check and installation.'
  s.description      = <<-DESC
Flutter plugin to check eSIM support and install eSIM profiles on Android and iOS
using official system-supported provisioning flows.
  DESC
  s.homepage         = 'https://github.com/elvin5002/esim_manager'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Elvin Seyfullayev' => 'elvin@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency       'Flutter'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
end
