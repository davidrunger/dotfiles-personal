# frozen_string_literal: true

require 'fileutils'
require 'guard/shell'
require '/Users/david/code/dotfiles/guardfiles/support/guard_support'

if !File.exist?('./personal/bash.sh')
  File.write(
    './personal/bash.sh',
    <<~BASH
      #!/usr/bin/env bash

    BASH
  )
end

FileUtils.chmod('+x', './personal/bash.sh')

guard(:shell, all_on_start: true) do
  # https://web.archive.org/web/20200927034139/https://github.com/guard/listen/wiki/Duplicate-directory-errors
  directories(GuardSupport.directories_to_watch)

  watch(%r{
   ^(
   personal/bash.sh
   )$
  }x) do |_|
    begin
      system('clear')
      system('./personal/bash.sh', exception: true)
    rescue => error
      pp(error)
    end
    puts("Ran at #{Time.now}")
  end
end
