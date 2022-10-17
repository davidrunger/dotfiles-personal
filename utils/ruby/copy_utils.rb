# frozen_string_literal: true

require 'amazing_print'

module CopyUtils
  def cpp(input = nil)
    str = (input || self).to_s
    IO.popen('pbcopy', 'w') { |f| f << str }
    if str.size < 100
      puts("Copied '#{str}' to clipboard.".green)
    else
      puts("Copied #{str.size} characters to clipboard.".green)
    end
    true
  end
end
