# frozen_string_literal: true

require 'active_support/core_ext/string/filters'
require 'guard/shell'
require 'memoist'
require '/Users/david/code/dotfiles/guardfiles/support/guard_support'

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

  ignore(%r{
    ^(
    .bundle/
    .github/
    coverage/|
    db/|
    log/|
    node_modules/|
    personal/|
    spec/fixtures/|
    tmp/
    )
  }x)

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
          #{ENV.fetch('TARGET_SPEC_FILES', nil)}
      SH
    rescue => error
      pp(error)
      puts(error.message)
      puts(error.backtrace)
    end

    # rubocop:disable Rails/TimeZone, Lint/RedundantCopDisableDirective
    "Done in #{(Time.now - start_time).round(2)} seconds."
    # rubocop:enable Rails/TimeZone, Lint/RedundantCopDisableDirective
  end
end
