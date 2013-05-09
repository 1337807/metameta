require 'spec_helper'

def delete_class(class_name)
  Object.send(:remove_const, class_name) if Object.const_defined? class_name
end

def delete_classes(*classes)
  classes.each { |class_name| delete_class(class_name) }
end

describe MetaMeta do
  before do
    MetaMeta.any_instance.stub(:bind_exit_handler)
  end

  context "given an instance method" do
    before do
      class NinetyNine
        def luftballoons
          "Auf ihrem weg zum horizont"
        end
      end

      ENV['COUNT_CALLS_TO'] = 'NinetyNine#luftballoons'
    end

    after do
      delete_class('NinetyNine')
    end

    it "increments the CALL_COUNT environment variable every time the target method is called" do
      meta_meta = MetaMeta.new

      expect { NinetyNine.new.luftballoons }.to change(meta_meta, :call_count).from(0).to(1)
    end

    it "calls the original method with all of the arguments" do
      class NinetyNine
        def luftballoons(n, color)
          "Auf ihrem weg zum horizont"
        end
      end

      meta_meta = MetaMeta.new
      ninety_nine = NinetyNine.new

      ninety_nine.should_receive(:original_luftballoons).with(99, "akai")
      ninety_nine.luftballoons(99, "akai")
    end

    context "#override_target" do
      it "aliases the target method to original_method" do
        MetaMeta.new
        NinetyNine.new.original_luftballoons.should == "Auf ihrem weg zum horizont"
      end

      it "redefines the original method with a generated method definition" do
        new_definition = Proc.new { "Em seu caminho para o horizonte" }
        MetaMeta.any_instance.stub(:replacement_method).and_return(new_definition)
        MetaMeta.new

        NinetyNine.new.luftballoons.should == "Em seu caminho para o horizonte"
      end
    end
  end

  context "given a class method" do
    before do
      class NinetyNine
        def self.luftballoons
          "Auf ihrem weg zum horizont"
        end
      end

      ENV['COUNT_CALLS_TO'] = 'NinetyNine.luftballoons'
    end

    after do
      delete_class('NinetyNine')
    end

    it "increments the CALL_COUNT environment variable every time the target method is called" do
      meta_meta = MetaMeta.new

      expect { NinetyNine.luftballoons }.to change(meta_meta, :call_count).from(0).to(1)
    end

    it "calls the original method with all of the arguments" do
      class NinetyNine
        def self.luftballoons(n, color)
          "Auf ihrem weg zum horizont"
        end
      end

      meta_meta = MetaMeta.new

      NinetyNine.should_receive(:original_luftballoons).with(99, "akai")
      NinetyNine.luftballoons(99, "akai")
    end

    context "#override_target" do
      it "aliases the target method to original_method" do
        MetaMeta.new
        NinetyNine.original_luftballoons.should == "Auf ihrem weg zum horizont"
      end

      it "redefines the original method with a new instance method definition" do
        new_definition = Proc.new { "Em seu caminho para o horizonte" }
        MetaMeta.any_instance.stub(:replacement_method).and_return(new_definition)
        MetaMeta.new

        NinetyNine.luftballoons.should == "Em seu caminho para o horizonte"
      end
    end
  end

  context "raises an InvalidTargetError" do
    before do
      MetaMeta.any_instance.stub(:locked_on_target?).and_return(true)
    end

    it "raises an InvalidTargetError given a constant without '#' or '.'" do
      ENV['COUNT_CALLS_TO'] = "NinetyNineLuftballoons"
      expect { MetaMeta.new }.to raise_error MetaMeta::InvalidTargetError
    end

    it "raises an InvalidTargetError given a constant with '#' and '.'" do
      ENV['COUNT_CALLS_TO'] = "Ninety#nine.luftballoons"
      expect { MetaMeta.new }.to raise_error MetaMeta::InvalidTargetError
    end

    it "raises an InvalidTargetError given a constant that starts with a lowercase letter" do
      ENV['COUNT_CALLS_TO'] = "ninetyNineLuftballoons"
      expect { MetaMeta.new }.to raise_error MetaMeta::InvalidTargetError
    end
  end

  context "#parse_target" do
    before do
      MetaMeta.any_instance.stub(:locked_on_target?).and_return(:true)
      MetaMeta.any_instance.stub(:infect)
    end

    it "parses the target class given a class and an instance method" do
      ENV['COUNT_CALLS_TO'] = "NinetyNine#luftballoons"
      MetaMeta.new.target_class.should == 'NinetyNine'
    end

    it "parses the target class given a class and a class method" do
      ENV['COUNT_CALLS_TO'] = "NinetyNine.luftballoons"
      MetaMeta.new.target_class.should == 'NinetyNine'
    end

    it "parses the target modules given a namespaced class and an instance method" do
      ENV['COUNT_CALLS_TO'] = "Ninety::Nine.luftballoons"
      MetaMeta.new.target_modules.should == ['Ninety']
    end

    it "parses the target class given a namespaced class and an instance method" do
      ENV['COUNT_CALLS_TO'] = "Ninety::Nine.luftballoons"
      MetaMeta.new.target_class.should == 'Nine'
    end

    it "parses the target method given a class and an instance method" do
      ENV['COUNT_CALLS_TO'] = "NinetyNine#luftballoons"
      MetaMeta.new.target_method.should == 'luftballoons'
    end

    it "parses the target method given a class and a class method" do
      ENV['COUNT_CALLS_TO'] = "NinetyNine.luftballoons"
      MetaMeta.new.target_method.should == 'luftballoons'
    end

    it "parses the target method given a namespaced class and an instance method" do
      ENV['COUNT_CALLS_TO'] = "Ninety::Nine.luftballoons"
      MetaMeta.new.target_method.should == 'luftballoons'
    end
  end

  context "#locked_on_target?" do
    let(:meta_meta) { MetaMeta.new }

    before do
      MetaMeta.any_instance.stub(:infect)
      MetaMeta.any_instance.stub(:lie_in_wait)
    end

    after do
      delete_classes('Locutus', 'Borg')
    end

    it "returns true if the class and method are defined" do
      ENV['COUNT_CALLS_TO'] = "Borg#assimilate"
      class Borg; def assimilate; end; end
      meta_meta.should be_locked_on_target
    end

    it "returns true if the class is defined within a namespace" do
      ENV['COUNT_CALLS_TO'] = "Locutus::Borg#assimilate"
      module Locutus; class Borg; def assimilate; end; end; end
      meta_meta.should be_locked_on_target
    end

    it "returns false if the class is defined but not the method" do
      ENV['COUNT_CALLS_TO'] = "Borg#assimilate"
      class Borg; end
      meta_meta.should_not be_locked_on_target
    end

    it "returns false if the class is not defined" do
      ENV['COUNT_CALLS_TO'] = "Borg#assimilate"
      meta_meta.should_not be_locked_on_target
    end
  end

  context "#target_method_defined?" do
    let(:meta_meta) { MetaMeta.new }

    before do
      MetaMeta.any_instance.stub(:locked_on_target?).and_return(:true)
      MetaMeta.any_instance.stub(:infect)
    end

    after do
      delete_classes('Locutus', 'Borg')
    end

    it "returns false if the method is undefined" do
      ENV['COUNT_CALLS_TO'] = "Borg#assimilate"
      class Borg; end
      meta_meta.target_method_defined?.should be_false
    end

    it "returns true if the target method is defined as an instance method" do
      ENV['COUNT_CALLS_TO'] = "Borg#assimilate"
      class Borg; def assimilate; end; end
      meta_meta.target_method_defined?.should be_true
    end

    it "returns true if the target method is defined as a class method" do
      ENV['COUNT_CALLS_TO'] = "Borg.assimilate"
      class Borg; def self.assimilate; end; end
      meta_meta.target_method_defined?.should be_true
    end

    it "returns true if the target method is defined within a namespaced class as an instance method" do
      ENV['COUNT_CALLS_TO'] = "Locutus::Borg#assimilate"
      module Locutus; class Borg; def assimilate; end; end; end
      meta_meta.target_method_defined?.should be_true
    end

    it "returns true if the target method is defined within a namespaced class as a class method" do
      ENV['COUNT_CALLS_TO'] = "Locutus::Borg.assimilate"
      module Locutus; class Borg; def self.assimilate; end; end; end
      meta_meta.target_method_defined?.should be_true
    end
  end

  context "#validate_target" do
    let(:meta_meta) { MetaMeta.new }

    before do
      ENV['COUNT_CALLS_TO'] = "Borg#assimilate"
      class Borg; def assimilate; end; end
    end

    after do
      delete_class('Borg')
    end

    it "returns true given a class name and instance method" do
      meta_meta.validate_target('Class#method').should be_true
    end

    it "returns true given a namespaced class and instance method" do
      meta_meta.validate_target('Module::Class#method').should be_true
    end

    it "returns true given a namespaced class and class method" do
      meta_meta.validate_target('Module::Class.method').should be_true
    end

    it "returns true given a class name and class method" do
      meta_meta.validate_target('Class.method').should be_true
    end

    it "returns false given a constant with both '#' and '.'" do
      meta_meta.validate_target('Class#method.other_method').should be_false
    end

    it "returns false given a constant without '#' or '.'" do
      meta_meta.validate_target('LonelyClassName').should be_false
    end

    it "returns false given a constant that does not start with a capital letter" do
      meta_meta.validate_target('classesStartWithCapitalLetters').should be_false
    end
  end

  context "#define_namespaced_class" do
    let(:meta_meta) { MetaMeta.new }

    before do
      ENV['COUNT_CALLS_TO'] = "Picard::Locutus::Borg#assimilate"
      MetaMeta.any_instance.stub(:locked_on_target?).and_return(true)
      MetaMeta.any_instance.stub(:infect)
    end

    after do
      delete_classes('Picard', 'Locutus', 'Borg')
    end

    it "defines the target modules" do
      meta_meta.define_namespaced_class
      Object.const_get('Picard').const_get('Locutus').should == Picard::Locutus
    end

    it "defines the target class within the namespace" do
      meta_meta.define_namespaced_class
      Object.const_get('Picard').const_get('Locutus').const_get('Borg').should == Picard::Locutus::Borg
    end

    it "does not define the class in a partial namespace" do
      meta_meta.define_namespaced_class
      expect { Object.const_get('Picard').const_get('Borg') }.to raise_error NameError
      expect { Object.const_get('Locutus').const_get('Borg') }.to raise_error NameError
    end
  end

  context "#define_method_added_trap" do
    let(:meta_meta) { MetaMeta.new }

    before do
      MetaMeta.any_instance.stub(:locked_on_target?).and_return(true)
      MetaMeta.any_instance.stub(:infect)
    end

    after do
      delete_classes('Borg')
    end

    context "given an instance method" do
      before do
        ENV['COUNT_CALLS_TO'] = "Borg#assimilate"
        meta_meta.define_namespaced_class
      end

      it "defines 'method_added' on the meta class" do
        meta_meta.define_method_added_trap
        Borg.respond_to?(:method_added).should be_true
      end

      it "calls back to infect if the target method is added" do
        meta_meta.define_method_added_trap
        meta_meta.should_receive(:infect)
        class Borg; def assimilate; end; end
      end
    end

    context "given a class method" do
      before do
        ENV['COUNT_CALLS_TO'] = "Borg.assimilate"
        meta_meta.define_namespaced_class
      end

      it "defines 'singleton_method_added' on the meta class" do
        meta_meta.define_method_added_trap
        Borg.respond_to?(:singleton_method_added).should be_true
      end

      it "calls back to infect if the target method is added" do
        meta_meta.define_method_added_trap
        meta_meta.should_receive(:infect)
        class Borg; def self.assimilate; end; end
      end
    end
  end

  context "#remove_method_added_trap" do
    let(:meta_meta) { MetaMeta.new }

    before do
      MetaMeta.any_instance.stub(:locked_on_target?).and_return(true)
      MetaMeta.any_instance.stub(:infect)
    end

    after do
      delete_classes('Borg')
    end

    context "given an instance method" do
      before do
        ENV['COUNT_CALLS_TO'] = "Borg#assimilate"
        meta_meta.define_namespaced_class
        meta_meta.define_method_added_trap
      end

      context "when method_added already exists" do
        it "removes 'method_added' on the meta class" do
          meta_meta.remove_method_added_trap
          Borg.respond_to?(:method_added).should be_false
        end

        it "does not call back to infect if the target method is added" do
          meta_meta.remove_method_added_trap
          meta_meta.should_not_receive(:infect)
          class Borg; def assimilate; end; end
        end
      end
    end

    context "given a class method" do
      before do
        ENV['COUNT_CALLS_TO'] = "Borg.assimilate"
        meta_meta.define_namespaced_class
        meta_meta.define_method_added_trap
      end

      it "removes 'singleton_method_added' on the meta class" do
        meta_meta.remove_method_added_trap
        Borg.respond_to?(:singleton_method_added).should be_false
      end

      it "does not call back to infect if the target method is added" do
        meta_meta.remove_method_added_trap
        meta_meta.should_not_receive(:infect)
        class Borg; def self.assimilate; end; end
      end
    end
  end

  context "#define_include_trap" do
    let(:meta_meta) { MetaMeta.new }

    before do
      MetaMeta.any_instance.stub(:locked_on_target?).and_return(true)
      MetaMeta.any_instance.stub(:infect)
    end

    before do
      ENV['COUNT_CALLS_TO'] = "Borg#assimilate"
      meta_meta.define_namespaced_class
    end

    after do
      delete_classes('Borg', 'HiveMind')
    end

    it "defines include on the target class" do
      meta_meta.define_include_trap
      Borg.should respond_to :include
    end

    it "calls back to method_alert when include is called if the included module defines the method" do
      meta_meta.define_include_trap
      meta_meta.should_receive(:method_alert)
      module HiveMind; def assimilate; end; end
      Borg.send(:include, HiveMind)
    end

    it "does not call back to method_alert when include is called if included module does not define the method" do
      meta_meta.define_include_trap
      meta_meta.should_not_receive(:method_alert)
      module HiveMind; end
      Borg.send(:include, HiveMind)
    end
  end

  context "#define_extend_trap" do
    let(:meta_meta) { MetaMeta.new }

    before do
      MetaMeta.any_instance.stub(:locked_on_target?).and_return(true)
      MetaMeta.any_instance.stub(:infect)
    end

    before do
      ENV['COUNT_CALLS_TO'] = "Borg.assimilate"
      meta_meta.define_namespaced_class
      meta_meta.define_extend_trap
    end

    after do
      delete_classes('Borg', 'HiveMind')
    end

    it "defines extend on the target class" do
      Borg.method_defined?(:extend).should be_true
    end

    it "calls back to method_alert when extend is called if the extended module defines the method" do
      meta_meta.should_receive(:method_alert)
      module HiveMind; def assimilate; end; end
      Borg.send(:extend, HiveMind)
    end

    it "does not call back to method_alert when include is called if included module does not define the method" do
      meta_meta.should_not_receive(:method_alert)
      module HiveMind; end
      Borg.send(:extend, HiveMind)
    end
  end
end
