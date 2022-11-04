# frozen_string_literal: true

require 'fileutils'
require 'guard/shell'
require '/Users/david/code/dotfiles/guardfiles/support/guard_support'

if !File.exist?('./personal/crystal.cr')
  File.write(
    './personal/crystal.cr',
    <<~CRYSTAL)
      p! 1 + 1
    CRYSTAL
end

guard(:shell, all_on_start: true) do
  # https://web.archive.org/web/20200927034139/https://github.com/guard/listen/wiki/Duplicate-directory-errors
  directories(GuardSupport.directories_to_watch)

  watch(%r{
   ^(
   personal/crystal.cr
   )$
  }x) do |_|
    begin
      system('clear')
      system('crystal personal/crystal.cr', exception: true)
    rescue => error
      pp(error)
    end
    puts("Ran at #{Time.now}")
  end
end
