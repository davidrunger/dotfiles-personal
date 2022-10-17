# frozen_string_literal: true

# NOTE! Because of the `.rb` extension, IRB doesn't automatically load this. That's what we want,
# because, if IRB does automatically load it, then IRB doesn't respect project-local settings.
# Instead, create a project-local `.irbrc` file, and in it put `load '/Users/david/.irbrc.rb'`.

require_relative './utils/ruby/copy_utils.rb'

def skip!
  $stop_skipping_at = Time.at(Integer(Time.now) + 5)
end

def subl(filename = nil)
  system("subl #{filename}")
end

class Method
  def sl
    source_location&.map(&:to_s)&.join(':')
  end

  def s
    return nil if sl.blank?

    subl(sl)
  end
end

class Object
  def m(method_name)
    method(method_name)
  end
end
Object.prepend(CopyUtils)

class Time
  def cppa
    I18n.l(self, format: :long).gsub(/\s+/, ' ').cpp
  end

  def cppz
    in_time_zone.cppz
  end
end

if defined?(ActiveSupport)
  class ActiveSupport::TimeWithZone
    def cppa
      I18n.l(self, format: :long).gsub(/\s+/, ' ').cpp
    end

    def cppz
      utc.iso8601.cpp
    end
  end
end

class String
  def cpp
    # copying SQL, e.g. CandidateAssessmentAttempt.select(:id, :remote_challenge_id).to_sql.cpp
    if start_with?('SELECT')
      super(tr('"', '')) # remove double quotes (from around table names, etc.)
    else
      super(self)
    end
  end

  def ccpp
    camelize.cpp
  end

  def ucpp
    underscore.cpp
  end

  # "Sublime regex (for searching)"
  def sr
    underscore.gsub('_', '.?').cpp
  end
end

class Numeric
  def cpp
    super(self)
  end
end

class Array
  def cpp
    super(to_json.gsub(',', ', ')[1..-2]) # spaces between commas and drop brackets for SQL
  end
end
