class MetaMeta
  attr_reader :env_constant, :target_class, :target_method
  attr_accessor :call_count

  def initialize
    @env_constant = ENV['COUNT_CALLS_TO']
    @call_count = 0
    infect
  end

  def infect
    parse_target
    override_target
    bind_exit_handler
  end

  def parse_target
    raise InvalidTargetError unless validate_target(env_constant)
    @target_class = extract_class(env_constant)
    @target_method = extract_method(env_constant)
  end

  def override_target
    define_alias_method
    supplant_method
  end

  def bind_exit_handler
    constant_class.send(:at_exit, &print_call_count)
  end

  def print_call_count
    Proc.new { puts "#{env_constant} called #{call_count} times" }
  end

  def supplant_method
    if target_is_instance_method?
      define_instance_method
    else
      define_class_method
    end
  end

  def define_instance_method
    constant_class.send(:define_method, target_method, replacement_method)
  end

  def define_class_method
    constant_class.send(:define_singleton_method, target_method, replacement_method)
  end

  def replacement_method
    original_method = alias_method_name
    meta_meta = self
    Proc.new { |*args| meta_meta.call_count += 1; send(original_method, *args) }
  end

  def define_alias_method
    if target_is_instance_method?
      constant_class.send(:alias_method, alias_method_name, target_method)
    else
      metaclass = class << constant_class; self; end
      metaclass.send(:alias_method, alias_method_name, target_method)
    end
  end

  def alias_method_name
    "original_#{target_method}"
  end

  def target_is_instance_method?
    env_constant.include? '#'
  end


  def constant_class
    Kernel.const_get(target_class)
  end

  def extract_class(target)
    target.gsub('.', '#').split('#').first
  end

  def extract_method(target)
    target.gsub('.', '#').split('#').last
  end

  def validate_target(env_constant)
    return false if String(env_constant).empty?
    return false unless env_constant.scan(/(#|\.){1}/).length == 1
    return false unless env_constant[0] == env_constant[0].upcase
    true
  end

  class InvalidTargetError < ArgumentError
    def initialize(msg = "Must supply COUNT_CALLS_TO in the form 'Class#method' or Class.method")
      super
    end
  end
end

MetaMeta.new unless ARGV.last == 'spec'
