# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Loo-Ber' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Loo-Ber
	pod 'Firebase/Core'
	pod 'Firebase/Database'
	pod 'Firebase/Auth'
  pod 'FirebaseUI/OAuth'
  pod 'FirebaseUI/Auth'
  pod 'FirebaseUI/Phone'
  pod 'FirebaseUI/Google'
	pod 'Firebase/Storage'
	pod 'GeoFire', :git => 'https://github.com/firebase/geofire-objc'
  pod 'Geofirestore', :git => 'https://github.com/imperiumlabs/GeoFirestore-iOS.git'
  pod 'Firebase/Performance'
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
  end
end
