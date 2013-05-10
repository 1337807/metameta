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

  context "#valid_target?" do
    let(:target) { Target.new('Borg#assimilate') }

    it "returns true given a class name and instance method" do
      target.should be_valid_target
    end

    it "returns true given a namespaced class and instance method" do
      target.target_name = 'Borg::Locutus#assimilate'
      target.should be_valid_target
    end

    it "returns true given a namespaced class and class method" do
      target.target_name = 'Borg::Locutus.assimilate'
      target.should be_valid_target
    end

    it "returns true given a class name and class method" do
      target.target_name = 'Borg.assimilate'
      target.should be_valid_target
    end

    it "returns false given a constant with both '#' and '.'" do
      target.target_name = 'Borg.Locutus#assimilate'
      target.should_not be_valid_target
    end

    it "returns false given a constant without '#' or '.'" do
      target.target_name = 'Borg'
      target.should_not be_valid_target
    end

    it "returns false given a constant that does not start with a capital letter" do
      target.target_name = 'borg'
      target.should_not be_valid_target
    end
  end

  context "raises an InvalidTargetError" do
    it "raises an InvalidTargetError given a constant without '#' or '.'" do
      error = Target::InvalidTargetNameError
      expect { Target.new("NinetyNineLuftballoons") }.to raise_error error
    end

    it "raises an InvalidTargetError given a constant with '#' and '.'" do
      error = Target::InvalidTargetNameError
      expect { Target.new("NinetyNine#luft.balloons") }.to raise_error error
    end

    it "raises an InvalidTargetError given a constant that starts with a lowercase letter" do
      error = Target::InvalidTargetNameError
      expect { Target.new("ninetyNineLuftballoons") }.to raise_error error
    end
  end
end
