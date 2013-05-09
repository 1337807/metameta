require 'spec_helper'

describe MetaMeta do
  context "given an instance method" do
    before do
      class NinetyNine
        def luftballoons
          "Auf ihrem weg zum horizont"
        end
      end

      ENV['COUNT_CALLS_TO'] = 'NinetyNine#luftballoons'
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

  it "raises an InvalidTargetError given a constant without '#' or '.'" do
    ENV['COUNT_CALLS_TO'] = "NinetyNineLuftballoons"
    expect { MetaMeta.new.set_attributes }.to raise_error MetaMeta::InvalidTargetError
  end

  it "raises an InvalidTargetError given a constant with '#' and '.'" do
    ENV['COUNT_CALLS_TO'] = "Ninety#nine.luftballoons"
    expect { MetaMeta.new.set_attributes }.to raise_error MetaMeta::InvalidTargetError
  end

  it "raises an InvalidTargetError given a constant that starts with a lowercase letter" do
    ENV['COUNT_CALLS_TO'] = "ninetyNineLuftballoons"
    expect { MetaMeta.new.set_attributes }.to raise_error MetaMeta::InvalidTargetError
  end

  context "#parse_target" do
    before do
      MetaMeta.any_instance.stub(:override_target)
      MetaMeta.any_instance.stub(:bind_exit_handler)
    end

    it "parses the target class given a class and an instance method" do
      ENV['COUNT_CALLS_TO'] = "NinetyNine#luftballoons"
      MetaMeta.new.target_class.should == 'NinetyNine'
    end

    it "parses the target class given a class and a class method" do
      ENV['COUNT_CALLS_TO'] = "NinetyNine.luftballoons"
      MetaMeta.new.target_class.should == 'NinetyNine'
    end

    it "parses the target class given a namespaced class and an instance method" do
      ENV['COUNT_CALLS_TO'] = "Ninety::Nine.luftballoons"
      MetaMeta.new.target_class.should == 'Ninety::Nine'
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

  context "#validate_target" do
    let(:meta_meta) { MetaMeta.new }

    before do
      MetaMeta.any_instance.stub(:infect)
    end

    it "returns true given a class name and instance method" do
      meta_meta.validate_target('Class#method').should be_true
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
end
