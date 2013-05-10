class Target
  attr_accessor :target_name, :method_name, :class_name, :module_names,
                :class_constant

  def initialize(target_name)
    @target_name = target_name
    raise InvalidTargetNameError unless valid_target?

    @method_name = parse_method_name
    @class_name = parse_class_name
    @module_names = parse_module_names
  end

  def parse_method_name
    target_name.gsub('.', '#').split('#').last
  end

  def parse_class_name
    target_name.gsub('.', '#').split('#').first.split('::').last
  end

  def parse_module_names
    target_name.gsub('.', '#').split('#').first.split('::')[0..-2]
  end

  def valid_target?
    return false if String(target_name).empty?
    return false unless target_name.scan(/(#|\.){1}/).length == 1
    return false unless target_name[0] == target_name[0].upcase
    true
  end

  class InvalidTargetNameError < ArgumentError
    def initialize(msg = "Must supply target name in the form 'Class#method' or Class.method")
      super
    end
  end
end
