# frozen_string_literal: true

# Example:
#     Printer.print_in_place('11MB 294K/s')
#     sleep(0.4)
#     Printer.print_in_place('20KB')
# This just prints on a single line in the terminal.

class Printer
  class << self
    def printing_in_place
      printer = new
      yield(printer)
      puts if !printer.broke_out
    end
  end

  attr_reader :broke_out

  def print_in_place(string)
    # https://stackoverflow.com/a/14971522/4009384
    print("\r\e[J#{string}")
  end

  def break_out
    puts
    @broke_out = true
  end
end
