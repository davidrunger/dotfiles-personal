# frozen_string_literal: true

require 'guard/shell'
require '/Users/david/code/dotfiles/guardfiles/support/guard_support'

guard(:shell, all_on_start: true) do
  # https://web.archive.org/web/20200927034139/https://github.com/guard/listen/wiki/Duplicate-directory-errors
  directories(GuardSupport.directories_to_watch)

  watch(%r{
   ^(
   personal/ruby.rb$
   )
  }x) do |_|
    begin
      system('clear')
      load('./personal/ruby.rb')
    rescue => error
      pp(error)
    end
    puts("Ran at #{Time.now}")
  end
end
