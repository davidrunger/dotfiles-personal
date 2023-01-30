# frozen_string_literal: true

require 'fileutils'
require 'guard/shell'
require '/Users/david/code/dotfiles/guardfiles/support/guard_support'

FileUtils.chmod('+x', './personal/run_exercism_tests.sh')

guard(:shell, all_on_start: true) do
  watch(/.*/) do |guard_match_result|
    begin
      match = guard_match_result.instance_variable_get(:@match_result) || '[no match]'
      puts("Match for #{match} triggered execution.")
      system('clear')
      system('./personal/run_exercism_tests.sh', exception: true)
    rescue => error
      pp(error)
    end
    puts("Ran at #{Time.now}")
  end
end