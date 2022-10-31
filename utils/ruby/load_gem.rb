# frozen_string_literal: true

# rubocop:disable Style/TopLevelMethodDefinition
def load_gem(gem_name)
  rbenv_gem_path = Gem.paths.path.find { _1.include?('.rbenv') }
  matching_gem_directories = Dir["#{rbenv_gem_path}/gems/#{gem_name}-*"]
  latest_gem_directory =
    matching_gem_directories.max_by do |gem_directory_path|
      version_number = gem_directory_path.split('/').last.delete_prefix("#{gem_name}-")
      Gem::Version.new(version_number)
    end
  gem_lib_directory = "#{latest_gem_directory}/lib"
  $LOAD_PATH << gem_lib_directory
  require gem_name
end
# rubocop:enable Style/TopLevelMethodDefinition
