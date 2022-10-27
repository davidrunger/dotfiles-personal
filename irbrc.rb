# frozen_string_literal: true

# NOTE! Because of the `.rb` extension, IRB doesn't automatically load this. That's what we want,
# because, if IRB does automatically load it, then IRB doesn't respect project-local settings.
# Instead, create a project-local `.irbrc` file, and in it put `load '/Users/david/.irbrc.rb'`.

require_relative './utils/ruby/monkeypatch_repl.rb'
