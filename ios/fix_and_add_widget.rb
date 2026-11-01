require 'xcodeproj'

IOS_DIR = File.expand_path(__dir__)
PROJECT_PATH = File.join(IOS_DIR, 'Runner.xcodeproj')
TEAM_ID = '9JL6TJ7722'
APP_BUNDLE_ID = 'com.ilahi.tefekkur.ilahiTefekkur'
WIDGET_BUNDLE_ID = 'com.ilahi.tefekkur.ilahiTefekkur.HuzurWidget'
APP_PROFILE = 'Huzur_AppStore_Profile'
WIDGET_PROFILE = 'Huzur_Widget_AppStore_Profile'
APP_GROUP = 'group.com.ilahi.tefekkur'

project = Xcodeproj::Project.open(PROJECT_PATH)
runner = project.targets.find { |t| t.name == 'Runner' }
raise 'Runner target not found' unless runner

group = project.main_group.find_subpath('HuzurWidget', true)
group.set_source_tree('<group>')
group.set_path('HuzurWidget')
group.clear

swift_ref = group.new_file('HuzurWidget.swift')
group.new_file('Info.plist')
group.new_file('HuzurWidget.entitlements')

widget = project.targets.find { |t| t.name == 'HuzurWidgetExtension' }
widget ||= project.new_target(:app_extension, 'HuzurWidgetExtension', :ios, '16.0')

widget.source_build_phase.files.dup.each(&:remove_from_project)
widget.source_build_phase.add_file_reference(swift_ref, true)

runner_configs = runner.build_configurations.each_with_object({}) do |c, result|
  result[c.name] = c
end

widget.build_configurations.each do |config|
  runner_config = runner_configs[config.name]
  if runner_config&.base_configuration_reference
    config.base_configuration_reference = runner_config.base_configuration_reference
  end

  s = config.build_settings
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = WIDGET_BUNDLE_ID
  s['INFOPLIST_FILE'] = 'HuzurWidget/Info.plist'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['CODE_SIGN_ENTITLEMENTS'] = 'HuzurWidget/HuzurWidget.entitlements'
  s['SWIFT_VERSION'] = '5.0'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  s['SKIP_INSTALL'] = 'YES'
  s['CURRENT_PROJECT_VERSION'] = '$(FLUTTER_BUILD_NUMBER)'
  s['MARKETING_VERSION'] = '$(FLUTTER_BUILD_NAME)'
  s['LD_RUNPATH_SEARCH_PATHS'] =
    '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'

  if config.name == 'Release'
    s['CODE_SIGN_STYLE'] = 'Manual'
    s['CODE_SIGN_IDENTITY'] = 'Apple Distribution'
    s['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'Apple Distribution'
    s['DEVELOPMENT_TEAM'] = TEAM_ID
    s['PROVISIONING_PROFILE_SPECIFIER'] = WIDGET_PROFILE
    s['CODE_SIGNING_ALLOWED'] = 'YES'
  else
    s['CODE_SIGNING_ALLOWED'] = 'NO'
  end
end

# Runner depends on the widget extension.
runner.dependencies
  .select { |d| d.target&.name == widget.name }
  .drop(1)
  .each(&:remove_from_project)

unless runner.dependencies.any? { |d| d.target == widget }
  runner.add_dependency(widget)
end

# Embed the extension in Runner.app/PlugIns.
runner.copy_files_build_phases
  .select { |p| p.name == 'Embed App Extensions' || p.dst_subfolder_spec.to_s == '13' }
  .each(&:remove_from_project)

embed = runner.new_copy_files_build_phase('Embed App Extensions')
embed.dst_subfolder_spec = '13'
build_file = embed.add_file_reference(widget.product_reference, true)
build_file.settings = {
  'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy']
}

thin_index = runner.build_phases.index do |phase|
  phase.respond_to?(:name) && phase.name == 'Thin Binary'
end

if thin_index
  runner.build_phases.delete(embed)
  runner.build_phases.insert(thin_index, embed)
end

# Configure Runner's App Group entitlement and App Store signing.
runner.build_configurations.each do |config|
  s = config.build_settings
  s['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'

  if config.name == 'Release'
    s['CODE_SIGN_STYLE'] = 'Manual'
    s['CODE_SIGN_IDENTITY'] = 'Apple Distribution'
    s['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'Apple Distribution'
    s['DEVELOPMENT_TEAM'] = TEAM_ID
    s['PROVISIONING_PROFILE_SPECIFIER'] = APP_PROFILE
    s['CODE_SIGNING_ALLOWED'] = 'YES'
  end
end

# Keep the extension version and build number aligned with Flutter.
info_path = File.join(IOS_DIR, 'HuzurWidget', 'Info.plist')
info = File.read(info_path)

replacements = {
  /(<key>CFBundleIdentifier<\/key>\s*<string>).*?(<\/string>)/m =>
    '\\1$(PRODUCT_BUNDLE_IDENTIFIER)\\2',
  /(<key>CFBundleShortVersionString<\/key>\s*<string>).*?(<\/string>)/m =>
    '\\1$(FLUTTER_BUILD_NAME)\\2',
  /(<key>CFBundleVersion<\/key>\s*<string>).*?(<\/string>)/m =>
    '\\1$(FLUTTER_BUILD_NUMBER)\\2'
}

replacements.each do |pattern, replacement|
  raise "Info.plist key missing: #{pattern}" unless info.match?(pattern)
  info.sub!(pattern, replacement)
end

File.write(info_path, info)
project.save

puts 'Runner + HuzurWidgetExtension configured.'
puts "Team: #{TEAM_ID}"
puts "App: #{APP_BUNDLE_ID}"
puts "Widget: #{WIDGET_BUNDLE_ID}"
puts "App Group: #{APP_GROUP}"
