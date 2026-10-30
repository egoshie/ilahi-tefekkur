require 'xcodeproj'

project_path = File.expand_path('Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(project_path)

runner_target = project.targets.find { |t| t.name == 'Runner' }
raise 'Runner target not found!' unless runner_target

widget_group = project.main_group.find_subpath('HuzurWidget', true)
widget_group.clear
widget_group.set_source_tree('<group>')
widget_group.set_path('HuzurWidget')

swift_file_ref = widget_group.new_file('HuzurWidget.swift')
plist_file_ref = widget_group.new_file('Info.plist')

widget_target = project.targets.find { |t| t.name == 'HuzurWidgetExtension' }
unless widget_target
  widget_target = project.new_target(:app_extension, 'HuzurWidgetExtension', :ios, '16.0')
end

widget_target.source_build_phase.files.dup.each(&:remove_from_project)
widget_target.source_build_phase.add_file_reference(swift_file_ref, true)

widget_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_NAME'] = 'HuzurWidgetExtension'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.ilahi.tefekkur.HuzurWidget'
  config.build_settings['INFOPLIST_FILE'] = 'HuzurWidget/Info.plist'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
  config.build_settings['SKIP_INSTALL'] = 'YES'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '6'
  config.build_settings['MARKETING_VERSION'] = '4.2.0'
  config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
  config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
  config.build_settings['CODE_SIGN_IDENTITY'] = ''
end

unless runner_target.dependencies.any? { |d| d.target == widget_target }
  runner_target.add_dependency(widget_target)
end

embed_phase = runner_target.copy_files_build_phases.find { |p| p.name == 'Embed App Extensions' }
unless embed_phase
  embed_phase = runner_target.new_copy_files_build_phase('Embed App Extensions')
  embed_phase.dst_subfolder_spec = '13'
end

unless embed_phase.files_references.include?(widget_target.product_reference)
  build_file = embed_phase.add_file_reference(widget_target.product_reference, true)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

project.save
puts 'HuzurWidgetExtension target verified and embedded into Runner.app/PlugIns!'
