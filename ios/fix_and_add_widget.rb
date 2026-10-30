require 'xcodeproj'
project_path = File.expand_path('Runner.xcodeproj', dir)
project = Xcodeproj::Project.open(project_path)
runner_target = project.targets.find { |t| t.name == 'Runner' }
raise 'Runner target not found!' unless runner_target
runner_target.copy_files_build_phases.each do |phase|
if phase.name&.include?('Embed') || phase.dst_subfolder_spec == "13"
phase.remove_from_project
end
end
runner_target.dependencies.each do |dep|
if dep.target&.name == 'HuzurWidgetExtension'
dep.remove_from_project
end
end
widget_target = project.targets.find { |t| t.name == 'HuzurWidgetExtension' }
unless widget_target
widget_target = project.new_target(:app_extension, 'HuzurWidgetExtension', :ios, '16.0')
group = project.main_group.find_subpath('HuzurWidget', true)
group.set_source_tree('')
if File.exist?('HuzurWidget/HuzurWidget.swift')
ref = group.new_reference('HuzurWidget/HuzurWidget.swift')
widget_target.source_build_phase.add_file_reference(ref, true)
end
end
runner_bundle_id = 'com.ilahi.tefekkur'
runner_target.build_configurations.each do |config|
b_id = config.build_settings['PRODUCT_BUNDLE_IDENTIFIER']
runner_bundle_id = b_id if b_id && !b_id.empty?
config.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = 'Huzur'
end
widget_target.build_configurations.each do |config|
config.build_settings['PRODUCT_NAME'] = 'HuzurWidgetExtension'
config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{runner_bundle_id}.HuzurWidget"
config.build_settings['INFOPLIST_FILE'] = 'HuzurWidget/Info.plist'
config.build_settings['SWIFT_VERSION'] = '5.0'
config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
config.build_settings['SKIP_INSTALL'] = 'NO'
config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
end
project.save
puts 'HuzurWidgetExtension hedefi döngüsüz olarak hazırlandı!'
