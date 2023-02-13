# frozen_string_literal: true

require 'guard/shell'
require '/Users/david/code/dotfiles/guardfiles/support/guard_support'

guard(:shell, all_on_start: true) do
  directories_to_watch = GuardSupport.directories_to_watch

  # https://web.archive.org/web/20200927034139/https://github.com/guard/listen/wiki/Duplicate-directory-errors
  directories(directories_to_watch)

  watch_regex =
    %r{^(
      #{directories_to_watch.map { "#{_1}/.*" }.join("|\n")}
    )}x

  watch(watch_regex) do |guard_match_result|
    begin
      match = guard_match_result.instance_variable_get(:@match_result) || '[no match]'
      puts("Match for #{match} triggered execution.")
      system('clear', exception: true)
      system('spring rails runner ./personal/runner.rb', exception: true)
    rescue => error
      pp(error) # rubocop:disable Lint/Debugger
    end
    # rubocop:disable Rails/TimeZone, Lint/RedundantCopDisableDirective
    puts("Ran at #{Time.new}")
    # rubocop:enable Rails/TimeZone, Lint/RedundantCopDisableDirective
  end
end
