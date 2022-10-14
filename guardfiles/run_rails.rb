# frozen_string_literal: true

require 'guard/shell'

guard(:shell, all_on_start: true) do
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
    puts("Ran at #{Time.now}")
  end
end
