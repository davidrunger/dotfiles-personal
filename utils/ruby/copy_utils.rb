# frozen_string_literal: true

require_relative './load_gem'
load_gem 'amazing_print' if !defined?(AmazingPrint)

module CopyUtils
  def cpp(input = nil)
    str = (input || self).to_s
    IO.popen('pbcopy', 'w') { |f| f << str }
    if str.size < 100
      puts(AmazingPrint::Colors.green("Copied '#{str}' to clipboard."))
    else
      puts(AmazingPrint::Colors.green("Copied #{str.size} characters to clipboard."))
    end
    true
  end
end
