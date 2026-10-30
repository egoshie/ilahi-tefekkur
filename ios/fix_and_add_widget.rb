require 'xcodeproj'

project_path = File.expand_path('Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(project_path)

runner_target = project.targets.find { |t| t.name == 'Runner' }
raise 'Runner target not found!' unless runner_target

# 1. Cycle inside Runner hatasını önlemek için Runner üzerindeki eski widget dependency ve Embed fazlarını kaldır
runner_target.dependencies.dup.each do |dep|
  if dep.target && dep.target.name == 'HuzurWidgetExtension'
    dep.remove_from_project
  end
end

runner_target.copy_files_build_phases.dup.each do |phase|
  if phase.name == 'Embed App Extensions' || phase.dst_subfolder_spec == '13'
    runner_target.build_phases.delete(phase)
  end
end

# 2. HuzurWidget grup ve dosya referanslarını temiz şekilde oluştur
widget_group = project.main_group.find_subpath('HuzurWidget', true)
widget_group.clear
widget_group.set_source_tree('<group>')
widget_group.set_path('HuzurWidget')

swift_file_ref = widget_group.new_file('HuzurWidget.swift')
widget_group.new_file('Info.plist')

# 3. Bağımsız HuzurWidgetExtension hedefini oluştur / güncelle
widget_target = project.targets.find { |t| t.name == 'HuzurWidgetExtension' }
unless widget_target
  widget_target = project.new_target(:app_extension, 'HuzurWidgetExtension', :ios, '16.0')
end

widget_target.source_build_phase.files.dup.each(&:remove_from_project)
widget_target.source_build_phase.add_file_reference(swift_file_ref, true)

widget_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_NAME'] = 'HuzurWidgetExtension'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.ilahi.tefekkur.ilahiTefekkur.HuzurWidget'
  config.build_settings['INFOPLIST_FILE'] = 'HuzurWidget/Info.plist'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
  config.build_settings['SKIP_INSTALL'] = 'NO'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '7'
  config.build_settings['MARKETING_VERSION'] = '4.3.0'
  config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
  config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
  config.build_settings['CODE_SIGN_IDENTITY'] = ''
end

project.save
puts 'Zero-Cycle HuzurWidgetExtension target configured successfully!'
