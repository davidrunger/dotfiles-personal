# frozen_string_literal: true

require 'guard/shell'
require '/Users/david/code/dotfiles/guardfiles/constants'

guard(:shell, all_on_start: true) do
  directories(DIRECTORIES_TO_WATCH)
  watch(%r{
   ^(
   personal/ruby.rb
   )$
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
