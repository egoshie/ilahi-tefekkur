require 'xcodeproj'

project_path = File.expand_path('Runner.xcodeproj', File.dirname(__FILE__))
project = Xcodeproj::Project.open(project_path)
runner_target = project.targets.find { |target| target.name == 'Runner' }
raise 'Runner target bulunamadı.' unless runner_target

widget_target = project.targets.find { |target| target.name == 'HuzurWidgetExtension' }
unless widget_target
  widget_target = project.new_target(:app_extension, 'HuzurWidgetExtension', :ios, '16.0')
end

widget_group = project.main_group.find_subpath('HuzurWidget', true)
widget_group.set_source_tree('<group>')
widget_group.set_path('HuzurWidget')

swift_ref = widget_group.files.find { |file| file.path == 'HuzurWidget.swift' }
swift_ref ||= widget_group.new_file('HuzurWidget.swift')
plist_ref = widget_group.files.find { |file| file.path == 'Info.plist' }
plist_ref ||= widget_group.new_file('Info.plist')

unless widget_target.source_build_phase.files_references.include?(swift_ref)
  widget_target.source_build_phase.add_file_reference(swift_ref)
end

base_bundle = runner_target.build_configurations.first.build_settings['PRODUCT_BUNDLE_IDENTIFIER']
base_bundle = 'com.ilahi.tefekkur' if base_bundle.nil? || base_bundle.to_s.empty? || base_bundle.to_s.include?('$(')

widget_target.build_configurations.each do |config|
  settings = config.build_settings
  settings['PRODUCT_NAME'] = 'HuzurWidgetExtension'
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = base_bundle + '.HuzurWidget'
  settings['INFOPLIST_FILE'] = '$(SRCROOT)/HuzurWidget/Info.plist'
  settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  settings['SWIFT_VERSION'] = '5.0'
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  settings['SKIP_INSTALL'] = 'YES'
  settings['CODE_SIGN_ENTITLEMENTS'] = 'HuzurWidget/HuzurWidget.entitlements'
  settings['CURRENT_PROJECT_VERSION'] = '6'
  settings['MARKETING_VERSION'] = '4.2.0'
  settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
end

runner_target.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

unless runner_target.dependencies.any? { |dependency| dependency.target == widget_target }
  runner_target.add_dependency(widget_target)
end

embed_phase = runner_target.copy_files_build_phases.find do |phase|
  phase.name == 'Embed App Extensions' || phase.dst_subfolder_spec.to_s == '13'
end
unless embed_phase
  embed_phase = runner_target.new_copy_files_build_phase('Embed App Extensions')
  embed_phase.dst_subfolder_spec = '13'
end

unless embed_phase.files_references.include?(widget_target.product_reference)
  build_file = embed_phase.add_file_reference(widget_target.product_reference)
  build_file.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy'] }
end

project.save
puts 'HuzurWidgetExtension hedefi Runner içine eklendi veya güncellendi.'
