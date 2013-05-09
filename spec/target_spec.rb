require 'spec_helper'

describe Target do
  context "#parse_method_name" do
    it "parses an instance method name" do
      target = Target.new('Foo#bar')
      target.parse_method_name.should == 'bar'
    end

    it "parses a class method name" do
      target = Target.new('Foo.bar')
      target.parse_method_name.should == 'bar'
    end

    it "parses an instance method on a namespaced class" do
      target = Target.new('Foo::Bar.bar')
      target.parse_method_name.should == 'bar'
    end
  end

  context "#parse_class_name" do
    it "parses a class name with an instance method" do
      target = Target.new('Foo#bar')
      target.parse_class_name.should == 'Foo'
    end

    it "parses a class name with a class method" do
      target = Target.new('Foo.bar')
      target.parse_class_name.should == 'Foo'
    end

    it "parses a namespaced class name" do
      target = Target.new('Foo::Bar#baz')
      target.parse_class_name.should == 'Bar'
    end
  end

  context "#parse_modules_names" do
    it "parses module names with an instance method" do
      target = Target.new('Foo::Bar#baz')
      target.parse_module_names.should == ['Foo']
    end

    it "parses module names with an instance method" do
      target = Target.new('Foo::Bar.baz')
      target.parse_module_names.should == ['Foo']
    end

    it "parses multiple module names" do
      target = Target.new('Foo::Bar::Baz.buz')
      target.parse_module_names.should == ['Foo', 'Bar']
    end
  end
end
