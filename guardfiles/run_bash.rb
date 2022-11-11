# frozen_string_literal: true

require 'fileutils'
require 'guard/shell'
require '/Users/david/code/dotfiles/guardfiles/support/guard_support'

if !File.exist?('./personal/bash.sh')
  File.write(
    './personal/bash.sh',
    <<~BASH)
      #!/usr/bin/env bash

    BASH
end

FileUtils.chmod('+x', './personal/bash.sh')

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
      system('clear')
      system('./personal/bash.sh', exception: true)
    rescue => error
      pp(error)
    end
    puts("Ran at #{Time.now}")
  end
end
