# This is a Rails initializer with various patches/utilities that improve the Rails development
# experience. It's called `z.rb` so that it runs after all other initializers (since they are
# executed alphabetically).

if defined?(Pry)
  # Load the pry enhancements defined in `pryrc.rb` of dotfiles repo.
  load("#{Dir.home}/.pryrc")
end

if defined?(IRB)
  # Load the IRB enhancements defined in `irbrc.rb` of dotfiles repo.
  load("#{Dir.home}/.irbrc.rb")
end

if !String.instance_methods.include?(:red)
  require_relative "#{ENV['USER_HOME'] || Dir.home}/code/dotfiles/utils/ruby/string_patches.rb"
end

load("#{Dir.home}/code/dotfiles/utils/ruby/debug.rb")

# :nocov:
# rubocop:disable Style/TopLevelMethodDefinition
module Runger
end

if Rails.env.development?
  # Flipper features to always enable (since Flipper sometimes get cleared by flushing Redis)
  %i[disable_prerendering].each do |feature|
    Flipper.enable(feature)
  end

  # Flipper features to always list in the UI
  %i[automatic_user_login automatic_admin_login].each do |feature|
    originally_enabled = Flipper.enabled?(feature)
    Flipper.enable(feature)
    Flipper.disable(feature) if !originally_enabled
  end
end

$runger_redis = Redis.new(db: 2)

class Runger::RungerConfig
  include Singleton

  CONFIG_KEYS = %w[
    current_user
    log_ar_trace
    log_expensive_queries
    log_to_stdout
    scratch
  ].freeze

  CONFIG_KEYS.each do |config_key|
    define_method(config_key) do
      unless $runger_config_last_memoized_at && $runger_config_last_memoized_at >= 1.second.ago
        memoize_settings_from_redis
      end
      instance_variable_get("@#{config_key}")
    end

    define_method("#{config_key}?") do
      public_send(config_key).present?
    end
  end

  def memoize_settings_from_redis
    $runger_config_last_memoized_at = Time.current
    CONFIG_KEYS.each do |config_key|
      instance_variable_set("@#{config_key}", setting_in_redis(config_key))
    end
  end

  def setting_in_redis(setting_name)
    value = JSON($runger_redis.get(setting_name) || "null")

    if value && setting_name == "scratch"
      # rubocop:disable Security/MarshalLoad
      Marshal.load(Base64.decode64(value))
      # rubocop:enable Security/MarshalLoad
    else
      value
    end
  end

  def set_in_redis(key, value, clear_memo: false)
    $runger_redis.set(key, JSON.dump(value))
    if clear_memo
      $runger_config_last_memoized_at = nil
    end
    true
  end

  def as_json
    CONFIG_KEYS.index_with do |key|
      setting(key)
    end
  end

  def setting(key)
    instance_variable_get("@#{key}")
  end

  def print_config
    max_key_length = CONFIG_KEYS.map(&:size).max
    CONFIG_KEYS.sort.map do |key|
      value = setting_in_redis(key)
      puts("#{AmazingPrint::Colors.yellow(key.ljust(max_key_length + 1))}: #{value.ai}")
    end
    nil
  end
end

module Runger
  def self.config
    @config ||= Runger::RungerConfig.instance
  end

  def self.david_runger_caller_lines
    caller.select { |filename| filename.include?('/david_runger/') }.presence || caller
  end

  def self.log_puts(object = nil)
    write_log(string_for(:puts, object))
  end

  def self.string_for(method_name, object)
    string_io = StringIO.new
    string_io.send(method_name, object)
    string_io.rewind
    string_io.read.rstrip
  end

  def self.write_log(message)
    pairs =
      if ::Rails.env.test?
        if ::Rails.logger.respond_to?(:clear_tags!)
          ::Rails.logger.clear_tags!
        end
        [[::Rails.logger, :info]].tap do |pair_list|
          if Runger.config.log_to_stdout?
            pair_list << [self, :puts]
          end
        end
      else
        [[self, :puts]]
      end

    pairs.each do |(recipient, write_method)|
      recipient.send(write_method, message)
    end

    nil
  end
end

def show_runger_config
  Runger.config.print_config
end

Runger::RungerConfig::CONFIG_KEYS.each do |runger_config_key|
  define_method("#{runger_config_key}!") do |value = true, quiet: false, silent: false|
    if runger_config_key == "scratch"
      value = Base64.encode64(Marshal.dump(value))
    end

    Runger.config.set_in_redis(runger_config_key, value)

    unless quiet || silent
      show_runger_config
    end

    true
  end

  define_method(:"un#{runger_config_key}!") do
    Runger.config.set_in_redis(runger_config_key, false)
    show_runger_config
    true
  end

  define_method(:"with_#{runger_config_key}") do |&block|
    original_value = Runger.config.setting_in_redis(runger_config_key)
    Runger.config.set_in_redis(runger_config_key, true, clear_memo: true)

    block.call
  ensure
    Runger.config.set_in_redis(runger_config_key, original_value, clear_memo: true)
  end
end

ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, start, finish, _id, payload|
  log_expensive_queries = Runger.config.log_expensive_queries? && defined?(Rails::Server)
  log_ar_trace = Runger.config.log_ar_trace?

  if log_expensive_queries || log_ar_trace
    david_runger_caller_lines_until_logging =
      Runger.
        david_runger_caller_lines.
        take_while { |line| line.exclude?('config/initializers/z.rb') }.
        presence || david_runger_caller_lines
  end

  if log_expensive_queries
    time = finish - start
    $runger_expensive_queries ||= {}
    $runger_expensive_queries[time] = [
      "#{payload[:sql]} #{payload[:binds].map { |b| [b.name, b.value] }}",
      david_runger_caller_lines_until_logging,
    ]
  end

  if log_ar_trace
    puts
    puts("#{payload[:sql]} #{payload[:binds].map { |b| [b.name, b.value] }}".blue)
    puts(<<~LOG.squish)
      ^ the above query (took #{AmazingPrint::Colors.red((finish - start).round(3).to_s)} sec)
      was triggered by the below stack trace \\/
    LOG
    puts(david_runger_caller_lines_until_logging.map { AmazingPrint::Colors.yellow(_1) })
    puts("#{'-' * 100}\n")
  end
end

ActiveSupport::Notifications.subscribe('process_action.action_controller') do |*args|
  next unless Runger.config.log_expensive_queries?

  payload = args.extract_options!

  controller_name = payload[:controller]
  next if controller_name == 'AnonymousController' # this occurs in tests

  puts("\nMost expensive queries:")
  $runger_expensive_queries.sort.last(3).each do |time, (query, backtrace)|
    puts("#{AmazingPrint::Colors.red(time.round(3).to_s)} seconds")
    puts(AmazingPrint::Colors.blue(query))
    puts(backtrace.map { AmazingPrint::Colors.yellow(_1) })
    puts
  end

  $runger_expensive_queries = {}
end

# write ActiveRecord queries and other Rails logs in Sidekiq process to stdout in development
if Rails.env.development? && $PROGRAM_NAME.include?('sidekiq')
  puts('Logging to $stdout for Rails and ActiveRecord in Sidekiq process.')

  Rails.logger =
    ActiveSupport::Logger.new($stdout).
      tap { |logger| logger.formatter = ActiveSupport::Logger::SimpleFormatter.new }

  ActiveRecord::Base.logger =
    ActiveSupport::Logger.new($stdout).
      tap { |logger| logger.formatter = ActiveSupport::Logger::SimpleFormatter.new }

  puts('Improving Sidekiq logging.')

  require 'sidekiq/job_logger'
  require 'sidekiq/logger'

  module RungerSidekiqLoggerPatches
    def info(message = '')
      color =
        case message
        when 'start' then :yellow
        when 'done' then :green
        when 'fail' then :red
        else :whiteish
        end

      if message == 'start'
        puts(
          ((pattern = ' ▿ ') * (Integer(`tput cols`.rstrip) / pattern.size)).
            public_send(color),
        )
      end

      super(AmazingPrint::Colors.public_send(color, message))

      if message == 'done'
        puts(
          "#{(pattern = ' ▵ ') * (Integer(`tput cols`.rstrip) / pattern.size)}\n\n".
            public_send(color),
        )
      end

      if message == 'fail'
        Thread.new do
          # Give some time for exception to be printed.
          sleep(0.1)

          puts(
            "#{(pattern = ' ! ') * (Integer(`tput cols`.rstrip) / pattern.size)}\n\n".
              public_send(color),
          )
        end
      end
    end
  end

  module SidekiqExt; end

  class SidekiqExt::JobLogger < Sidekiq::JobLogger
    # This is basically copy-pasted from the Sidekiq source code, but we are adding
    # `:queue` and `:args` to `Sidekiq::Context` so that they'll be logged.
    def call(item, queue)
      start = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
      Sidekiq::Context.add(:queue, queue)
      json = JSON.dump(item['args'])
      Sidekiq::Context.add(
        :args,
        AmazingPrint::Colors.cyan(json.size <= 140 ? json : "#{json[0...140]}...]"),
      )
      @logger.info('start')

      yield

      Sidekiq::Context.add(:elapsed, elapsed(start))
      @logger.info('done')
      # rubocop:disable Lint/RescueException
      # This is what the Sidekiq source code does, so we'll do it here, too.
    rescue Exception
      # rubocop:enable Lint/RescueException
      Sidekiq::Context.add(:elapsed, elapsed(start))
      @logger.info('fail')

      raise
    end
  end

  Sidekiq.configure_server do |config|
    if ENV['REDIS_DATABASE_NUMBER'] == '3'
      config.logger = nil
    else
      Sidekiq::Logger.prepend(RungerSidekiqLoggerPatches)
      config[:job_logger] = SidekiqExt::JobLogger
    end
  end
end

module RungerApplicationControllerPatches
  def current_user
    if Rails.env.development?
      super_current_user = super
      config_user_identifier = Runger.config.current_user

      if config_user_identifier.blank?
        super_current_user
      else
        RequestStore.fetch("runger:current_user_by_config") do
          ube(config_user_identifier).tap do |user_by_config|
            if user_by_config.present? && user_by_config != super_current_user
              sign_in(user_by_config)
              # Having signed the user in, now allow logging out or logging in as a different user.
              Runger.config.current_user!(nil, quiet: true)
            end
          end
        end
      end
    else
      super
    end
  end

  def redirect_to(*args, **kwargs)
    Runger.log_puts(AmazingPrint::Colors.purple("Redirecting to: #{args.first} #{kwargs}"))
    Runger.log_puts(Runger.david_runger_caller_lines)
    super
  end

  def sign_in(*args)
    record = args.detect { |arg| arg.respond_to?(:email) }
    Runger.log_puts(AmazingPrint::Colors.purple("Signing in #{record.class.name} #{record.email}."))
    Runger.log_puts(Runger.david_runger_caller_lines)
    super
  end
end

Rails.application.reloader.to_prepare do
  ApplicationController.prepend(RungerApplicationControllerPatches)
end

def quiet_ar
  original_logger = ActiveRecord::Base.logger

  ActiveRecord::Base.logger = ActiveSupport::Logger.new("/dev/null")

  yield
ensure
  ActiveRecord::Base.logger = original_logger
end

# [u]ser [b]y [e]mail or id
def ube(id_or_email)
  if id_or_email.is_a?(Numeric) || id_or_email.match?(/\A\d+\z/)
    User.find(Integer(id_or_email))
  else
    User.find_by!(email: id_or_email)
  end
end

# [f]uzzy-find a [u]ser
def fu(recent_login_only: false)
  user_relation = User.reorder(:email)

  if recent_login_only
    user_relation = user_relation.where(current_sign_in_at: 1.year.ago..)
  end

  user_emails = quiet_ar { user_relation.pluck(:email) }

  if (selected_email = fzf(user_emails))
    ube(selected_email)
  end
end

# [s]et current_[u]ser
def su
  if (email_to_log_in = fu&.email)
    Runger.config.current_user!(email_to_log_in)
  end
end

def skip_for!(seconds)
  $stop_skipping_at = seconds.seconds.from_now
end

def d
  system('clear')
end

# [b]ench[m]ark [m]easure
def bmm
  result = nil
  exception = nil

  time =
    Benchmark.measure do
      result = yield
    rescue => exception
      # do nothing for now
    end.real

  puts(<<~LOG.squish)
    #{AmazingPrint::Colors.cyan('BENCHMARK TIME:')}
    Took
    #{AmazingPrint::Colors.purple('%.3f' % time.round(3))}
    seconds.
  LOG

  if exception
    raise exception
  else
    result
  end
end

module FixtureBuilder
  class Builder
    module RungerPatches
      protected

      def dump_tables
        puts
        super
      end
    end
    prepend RungerPatches
  end

  class Namer
    module RungerPatches
      def name(custom_name, *model_objects)
        print "#{custom_name} "
        super
      end
    end
    prepend RungerPatches
  end
end

class Array
  def rgc
    each_with_object(Hash.new(0)) { |e, h| h[e] += 1 ; h }.sort_by { |key, _value| key }.to_h
  end

  def rgcb
    each_with_object(Hash.new(0)) { |e, h| h[e] += 1 ; h }.sort_by { |_key, value| value * -1 }.to_h
  end
end

def jpf(file)
  JSON.parse(File.read(file))
end

if Rails.env.test?
  class ActiveRecord::Base
    module RungerPatches
      def inspect
        original = super
        (original.size > 200) ? "#{self.class.name}:#{id}" : original
      end
    end
    prepend RungerPatches
  end

  class RSpec::Core::Metadata::HashPopulator
    private

    def description_separator(parent_part, child_part)
      if parent_part.is_a?(Module) && child_part =~ /^(#|::|\.)/
        ''
      else
        ' / '
      end
    end
  end
end

class Rollbar::Notifier
  module RungerPatch
    def color(level)
      case level
      when 'info', 'debug' then :blue
      when 'warn', 'warning' then :yellow
      else :red
      end
    end

    def header(level)
      color = color(level)
      AmazingPrint::Colors.public_send(color, "Rollbar #{level}:")
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def error_log(level, args)
      message, exception, extra, context = extract_arguments(args)
      item = build_item(level, message, exception, extra, context)
      error_class, error_message =
        item.build_data.dig(:body, :trace, :exception).presence&.values_at(:class, :message)

      header =
        case
        when exception.present?
          exception.inspect
        when error_class.present? && error_message.present?
          "#{error_class}: #{error_message}"
        else
          message || 'NO MESSAGE'
        end

      if extra.present?
        header << "\n#{extra}"
      end

      if context.present?
        header << "\n#{context}"
      end

      message = header.public_send(color(level))

      if exception.present?
        message << "\n#{(exception.backtrace || []).join("\n")}"
      end

      message
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def log(level, *args)
      super_result = super

      if super_result == 'disabled'
        puts(<<~LOG)

          #{'▽  ▽  ▽  ▽  ▽  ▽  ▽  ▽  ▽  ▽  ▽  ▽'.public_send(color(level))}
          #{header(level)}
          #{error_log(level, args)}
          #{'△  △  △  △  △  △  △  △  △  △  △  △'.public_send(color(level))}

        LOG

      end

      super_result
    end
  end

  prepend(RungerPatch) if Rails.env.development?
end
# rubocop:enable Style/TopLevelMethodDefinition
# :nocov:
