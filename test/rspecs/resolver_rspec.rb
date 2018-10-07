require "securerandom"
require_relative "./base"

describe SfnParameters::Resolver do
  let(:resolver) do
    klass_name = SecureRandom.uuid.gsub(/(\d|-)/, "").capitalize
    instance_eval("class ::#{klass_name} < #{described_class.name}; end")
    Object.const_get(klass_name)
  end

  before { described_class.reset! }
  after { described_class.reset! }

  describe ".inherited" do
    it "should add class to list of resolvers" do
      r = resolver
      expect(described_class.resolvers).to include(r)
    end

    it "should not allow unnamed subclasses" do
      expect { Class.new(described_class) }.to raise_error(ArgumentError)
    end
  end

  describe ".resolvers" do
    it "should return empty list when no resolvers are defined" do
      expect(described_class.resolvers).to be_empty
    end

    it "should return list of defined resolvers" do
      resolver # forces creation of resolver
      expect(described_class.resolvers).not_to be_empty
    end
  end

  describe ".detect_resolver" do
    it "should find resolver by name" do
      r_name = resolver.name
      expect(described_class.detect_resolver(r_name)).to eq(resolver)
    end

    it "should find resolver without namespace" do
      instance_eval("module Outer; class Inner < #{described_class.name}; end; end")
      expect(described_class.detect_resolver("inner")).to be_kind_of(Class)
    end

    it "should find resolver with namespace" do
      instance_eval("module Outer; class Inner < #{described_class.name}; end; end")
      expect(described_class.detect_resolver("outer_inner")).to be_kind_of(Class)
    end

    it "should raise error when resolver is not found" do
      expect { described_class.detect_resolver("unknown") }.to raise_error(NameError)
    end
  end

  describe "#setup" do
    it "should call setup when new instance is created" do
      expect_any_instance_of(described_class).to receive(:setup)
      described_class.new(nil)
    end
  end

  describe "#resolve" do
    it "should raise a not implemented error" do
      expect { described_class.new(nil).resolve(nil) }.to raise_error(NotImplementedError)
    end
  end
end
