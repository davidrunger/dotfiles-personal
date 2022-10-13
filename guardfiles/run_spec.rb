# frozen_string_literal: true

require 'active_support/core_ext/string/filters'
require 'guard/shell'
require 'memoist'

class RspecPrefixer
  extend Memoist

  memoize \
  def rspec_prefix
    pp(["ENV.fetch('DISABLE_SPRING', nil)", ENV.fetch('DISABLE_SPRING', nil)])
    if project_uses_spring? && ENV.fetch('DISABLE_SPRING', nil) != '1'
      'spring '
    else
      'bin/'
    end
  end

  memoize \
  def project_uses_spring?
    return false if !File.exist?('Gemfile')

    File.read('Gemfile').match?(/gem ['"]spring['"]/)
  end
end

rspec_prefixer = RspecPrefixer.new

guard(:shell, all_on_start: true) do
  watch(%r{
   ^(
   app/|
   lib/|
   spec/|
   tools/|
   config/routes.rb$
   )
  }x) do |_|
    begin
      start_time = Time.now
      system('clear')
      system(<<~SH.squish)
        #{rspec_prefixer.rspec_prefix}rspec
          #{'-b' if ENV.fetch('RSPEC_BACKTRACE', nil) == '1'}
          #{ENV.fetch('TARGET_SPEC_FILES')}
      SH
    rescue => error
      pp(error)
      puts(error.message)
      puts(error.backtrace)
    end

    "Done in #{(Time.now - start_time).round(2)} seconds." # rubocop:disable Rails/TimeZone
  end
end
