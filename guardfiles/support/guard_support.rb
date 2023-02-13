# frozen_string_literal: true

require '/Users/david/code/dotfiles/guardfiles/support/monkeypatch_guard.rb'
require '/Users/david/code/dotfiles/utils/ruby/load_gem.rb'

load_gem 'memoist' if !defined?(Memoist)

module GuardSupport
  class << self
    extend Memoist

    # rubocop:disable Style/MutableConstant
    DIRECTORIES_TO_WATCH = {
      'crystal' => %w[app personal spec src],
    }
    DIRECTORIES_TO_WATCH.default_proc = proc { %w[app lib personal spec test] }
    DIRECTORIES_TO_WATCH.freeze
    # rubocop:enable Style/MutableConstant

    memoize \
    def directories_to_watch
      DIRECTORIES_TO_WATCH[guardfile_type].select { File.directory?(_1) }.freeze
    end

    memoize \
    def guardfile_type
      ENV.fetch('GUARDFILE_TYPE')
    end
  end
end
