class Target
  attr_reader :target_name
  attr_accessor :method_name, :class_name, :module_names, :class_constant

  def initialize(target_name)
    @target_name = target_name
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
end
