require 'xcodeproj'

project_path = File.expand_path('Runner.xcodeproj', __dir__)
abort("Xcode projesi bulunamadi: #{project_path}") unless File.file?(File.join(project_path, 'project.pbxproj'))

project = Xcodeproj::Project.open(project_path)
runner_target = project.targets.find { |target| target.name == 'Runner' }
abort('Runner target bulunamadi!') unless runner_target

bundle_id = runner_target.build_configurations
  .map { |config| config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] }
  .compact
  .find { |value| value.is_a?(String) && !value.empty? && !value.include?('$(') }

if bundle_id.nil?
  bundle_id = project.build_configurations
    .map { |config| config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] }
    .compact
    .find { |value| value.is_a?(String) && !value.empty? && !value.include?('$(') }
end

abort('Runner icin sabit PRODUCT_BUNDLE_IDENTIFIER bulunamadi. Xcode Runner target Bundle Identifier degerini duzenle.') if bundle_id.nil?

widget_target = project.targets.find { |target| target.name == 'HuzurWidgetExtension' }
unless widget_target
  widget_target = project.new_target(:app_extension, 'HuzurWidgetExtension', :ios, '16.0')
end

widget_group = project.main_group.find_subpath('HuzurWidget', true)
widget_group.set_source_tree('<group>')
widget_group.set_path('HuzurWidget')

find_or_add_file = lambda do |filename|
  reference = widget_group.children.find do |child|
    child.isa == 'PBXFileReference' && child.path == filename
  end
  reference || widget_group.new_file(filename)
end

swift_ref = find_or_add_file.call('HuzurWidget.swift')
find_or_add_file.call('Info.plist')

unless widget_target.source_build_phase.files_references.include?(swift_ref)
  widget_target.source_build_phase.add_file_reference(swift_ref)
end

widget_target.build_configurations.each do |config|
  settings = config.build_settings
  settings['PRODUCT_NAME'] = 'HuzurWidgetExtension'
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{bundle_id}.HuzurWidget"
  settings['INFOPLIST_FILE'] = 'HuzurWidget/Info.plist'
  settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  settings['SWIFT_VERSION'] = '5.0'
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
  settings['SKIP_INSTALL'] = 'YES'
  settings['CURRENT_PROJECT_VERSION'] = '5'
  settings['MARKETING_VERSION'] = '4.1.0'
  settings['CODE_SIGNING_ALLOWED'] = 'NO'
  settings['CODE_SIGNING_REQUIRED'] = 'NO'
  settings['CODE_SIGN_IDENTITY'] = ''
end

unless runner_target.dependencies.any? { |dependency| dependency.target == widget_target }
  runner_target.add_dependency(widget_target)
end

embed_phase = runner_target.copy_files_build_phases.find { |phase| phase.dst_subfolder_spec.to_s == '13' }
unless embed_phase
  embed_phase = runner_target.new_copy_files_build_phase('Embed App Extensions')
  embed_phase.dst_subfolder_spec = '13'
end

embed_file = embed_phase.files.find { |build_file| build_file.file_ref == widget_target.product_reference }
unless embed_file
  embed_file = embed_phase.add_file_reference(widget_target.product_reference)
end
embed_file.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy'] }

project.save
puts "HuzurWidgetExtension hazir: #{bundle_id}.HuzurWidget"
