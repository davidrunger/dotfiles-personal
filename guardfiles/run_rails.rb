# frozen_string_literal: true

require 'guard/shell'
require '/Users/david/code/dotfiles/guardfiles/support/guard_support'

guard(:shell, all_on_start: true) do
  # https://web.archive.org/web/20200927034139/https://github.com/guard/listen/wiki/Duplicate-directory-errors
  directories(GuardSupport.directories_to_watch)

  watch(%r{
   ^(
   personal/runner.rb
   )$
  }x) do |_|
    begin
      system('clear', exception: true)
      system('spring rails runner ./personal/runner.rb', exception: true)
    rescue => error
      pp(error)
    end
    # rubocop:disable Rails/TimeZone, Lint/RedundantCopDisableDirective
    puts("Ran at #{Time.new}")
    # rubocop:enable Rails/TimeZone, Lint/RedundantCopDisableDirective
  end
end
