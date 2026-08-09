require 'xcodeproj'

project_path = "Baluarte.xcodeproj"
project = Xcodeproj::Project.open(project_path)

# Create file reference for Config.xcconfig
xcconfig_path = "Config.xcconfig"
group = project.main_group
file_ref = group.find_file_by_path(xcconfig_path) || group.new_file(xcconfig_path)

# Apply xcconfig to all targets and configurations
project.build_configurations.each do |config|
  config.base_configuration_reference = file_ref
end

project.targets.each do |target|
  target.build_configurations.each do |config|
    config.base_configuration_reference = file_ref
    
    # Add custom keys to generated Info.plist
    config.build_settings['INFOPLIST_KEY_SUPABASE_URL'] = '$(SUPABASE_URL)'
    config.build_settings['INFOPLIST_KEY_SUPABASE_ANON_KEY'] = '$(SUPABASE_ANON_KEY)'
  end
end

project.save
puts "Successfully configured Config.xcconfig and Info.plist keys"
