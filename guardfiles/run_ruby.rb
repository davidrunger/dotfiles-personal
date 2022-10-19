# frozen_string_literal: true

require 'guard/shell'

guard(:shell, all_on_start: true) do
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
