# frozen_string_literal: true

require_relative './utils/ruby/monkeypatch_repl.rb'

Pry.config.pager = false
Pry.config.color = true

Pry.commands.alias_command('c', 'continue')
Pry.commands.alias_command('s', 'step')
Pry.commands.alias_command('n', 'next')
Pry.commands.alias_command('f', 'finish')
Pry.commands.alias_command('where', 'backtrace')
Pry.commands.alias_command('list', 'whereami')
Pry.commands.alias_command('fr', 'frame')

Pry::Commands.command(/^$/, 'repeat last command') do
  pry_instance.run_command(Pry.history.to_a.last)
end

require 'amazing_print'
# similar to `AmazingPrint.pry!`, but with `=> ` at the beginning
Pry.print = proc { |output, value| output.puts("=> #{value.ai}") }
