# frozen_string_literal: true

require_relative "#{Dir.home}/code/dotfiles/guardfiles/support/guard_support"
require 'active_support'
require 'active_support/core_ext/string/filters'
require 'guard/shell'
require 'memoist'

class RspecPrefixer
  extend Memoist

  memoize \
  def rspec_prefix
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
  # https://web.archive.org/web/20200927034139/https://github.com/guard/listen/wiki/Duplicate-directory-errors
  directories(GuardSupport.directories_to_watch)

  watch(%r{^(
    app/|
    lib/|
    spec/(?!fixtures/)|
    tools/|
    config/routes.rb$
  )}x) do |guard_match_result|
    begin
      match = guard_match_result.instance_variable_get(:@match_result) || '[no match]'
      puts("Match for #{match} triggered execution.")
      # rubocop:disable Rails/TimeZone, Lint/RedundantCopDisableDirective
      start_time = Time.now
      # rubocop:enable Rails/TimeZone, Lint/RedundantCopDisableDirective
      system('clear')
      system(<<~SH.squish)
        #{rspec_prefixer.rspec_prefix}rspec
          #{'-b' if ENV.fetch('RSPEC_BACKTRACE', nil) == '1'}
          #{ENV.fetch('TARGET_SPEC_FILES', nil)}
      SH
    rescue => error
      pp(error) # rubocop:disable Lint/Debugger
      puts(error.message)
      puts(error.backtrace)
    end

    # rubocop:disable Rails/TimeZone, Lint/RedundantCopDisableDirective
    "Done in #{(Time.now - start_time).round(2)} seconds."
    # rubocop:enable Rails/TimeZone, Lint/RedundantCopDisableDirective
  end
end
