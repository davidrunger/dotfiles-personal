# frozen_string_literal: true

require '/Users/david/code/dotfiles/utils/ruby/load_gem.rb'
require '/Users/david/code/dotfiles/guardfiles/support/monkeypatch_guard.rb'

load_gem 'memoist' if !defined?(Memoist)

module GuardSupport
  class << self
    extend Memoist

    memoize \
    def directories_to_watch
      %w[app lib personal spec].select { File.directory?(_1) }.freeze
    end
  end
end
