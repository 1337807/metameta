require 'target'

class MetaMeta
  attr_reader :env_constant, :target_modules, :target_class, :target_method
  attr_accessor :call_count

  def initialize
    @env_constant = ENV['COUNT_CALLS_TO']
    @call_count = 0

    parse_target

    if locked_on_target?
      infect
    else
      lie_in_wait
    end
  end

  def parse_target
    raise InvalidTargetError unless validate_target(env_constant)

    target = Target.new(env_constant)

    @target_modules = target.module_names
    @target_class = target.class_name
    @target_method = target.method_name
  end

  def infect
    override_target
    bind_exit_handler
  end

  def lie_in_wait
    define_namespaced_class
    set_traps
  end

  def set_traps
    define_method_added_trap
    define_include_trap
    define_extend_trap
  end

  def define_include_trap
    meta_meta = self
    target_method_name = target_method
    definition = Proc.new { |*args| super(*args); meta_meta.method_alert if method_defined?(target_method_name) }
    constant_metaclass.send(:define_method, :include, definition)
  end

  def define_extend_trap
    meta_meta = self
    target_method_name = target_method
    definition = Proc.new { |*args| super(*args); meta_meta.method_alert if respond_to?(target_method_name) }
    constant_metaclass.send(:define_method, :extend, definition)
  end

  def method_alert
    remove_method_added_trap
    infect
  end

  def define_namespaced_class
    modules = target_modules.inject(Object) do |memo, module_name|
      memo = memo.const_set(module_name, Module.new)
    end

    modules.const_set(target_class, Class.new)
  end

  def define_method_added_trap
    meta_meta = self
    target_method_name = target_method
    definition = Proc.new { |method_name| meta_meta.method_alert if method_name.to_s == target_method_name }

    if target_is_instance_method?
      constant_metaclass.send(:define_method, :method_added, definition)
    else
      constant_metaclass.send(:define_method, :singleton_method_added, definition)
    end
  end

  def constant_metaclass
    class << constant_namespaced_class; self; end
  end

  def remove_method_added_trap
    if target_is_instance_method?
      constant_metaclass.send(:remove_method, :method_added)
    else
      constant_metaclass.send(:remove_method, :singleton_method_added)
    end
  end

  def locked_on_target?
    if target_class_defined? && target_method_defined?
      true
    else
      false
    end
  end

  def target_class_defined?
    if target_modules.any?
      target_class_defined_within_module?
    else
      Object.const_defined?(target_class)
    end
  end

  def target_class_defined_within_module?
    constant_top_level_namespace.const_defined?(target_class)
  end

  def target_method_defined?
    if target_modules.any?
      target_method_defined_within_module?
    else
      method_in_class?(constant_class)
    end
  end

  def method_in_class?(search_class)
    search_class.respond_to?(target_method) || search_class.method_defined?(target_method)
  end

  def target_method_defined_within_module?
    method_in_class?(constant_namespaced_class)
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
    Object.const_get(target_class)
  end

  def constant_top_level_namespace
    Object.const_get(target_modules.first)
  end

  def constant_namespaced_class
    namespaced_class = target_modules + Array(target_class)

    namespaced_class.inject(Object) do |memo, constant|
      memo = memo.const_get(constant)
    end
  end

  def extract_modules(target)
    target.gsub('.', '#').split('#').first.split('::')[0..-2]
  end

  def extract_class(target)
    target.gsub('.', '#').split('#').first.split('::').last
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

MetaMeta.new unless ENV['META_META_ENVIRONMENT'] == 'test'
