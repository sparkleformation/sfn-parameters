require_relative "./base"

describe Sfn::Callback::ParametersInfrastructure do
  let(:ui) { double("ui") }
  let(:config) { Smash.new }
  let(:arguments) { [] }
  let(:api) { double("api") }
  let(:instance) { described_class.new(ui, config, arguments, api) }

  before { allow(ui).to receive(:debug) }

  describe "#load_file_for" do
    let(:stack_name) { "TEST-STACK" }
    let(:file_paths) { [] }

    before { allow(Dir).to receive(:glob).and_return(file_paths) }

    context "when no valid paths exist" do
      it "should return an empty value" do
        expect(instance.send(:load_file_for, stack_name)).to be_empty
      end
    end

    context "when multiple valid paths exist" do
      let(:file_paths) { ["PATH1", "PATH2"] }

      it "should raise an error" do
        expect { instance.send(:load_file_for, stack_name) }.to raise_error(ArgumentError)
      end
    end

    context "when single valid path exists" do
      let(:file_paths) { ["FILE_PATH"] }
      let(:bogo_config) { double("bogo_config", data: {}) }

      before { allow(Bogo::Config).to receive(:new).and_return(bogo_config) }
      after { instance.send(:load_file_for, stack_name) }

      it "should load data from file" do
        expect(Bogo::Config).to receive(:new).with(file_paths.first).
                                  and_return(bogo_config)
      end

      it "should extract data from from file" do
        expect(bogo_config).to receive(:data)
      end

      it "should unlock the data" do
        expect(instance).to receive(:unlock_content).with(bogo_config.data)
      end
    end
  end

  describe "#process_information_hash" do
    let(:info_hash) { Smash.new }
    let(:path) { [] }
    let(:config) {
      Smash.new(
        :parameters => Smash.new,
        :compile_parameters => Smash.new,
        :apply_stack => [],
        :apply_mapping => Smash.new,
        :options => {
          :tags => Smash.new
        },
      )
    }

    before { allow(instance).to receive(:config).and_return(config) }

    context "when template is set" do
      before { info_hash[:template] = "TEMPLATE" }

      it "should set the file in the configuration" do
        instance.send(:process_information_hash, info_hash, path)
        expect(config[:file]).not_to be_nil
        expect(config[:file]).to eq(info_hash[:template])
      end
    end

    context "when parameters are set" do
      let(:info_hash) {
        Smash.new(
          :parameters => {
            :key1 => 1,
            :key2 => 2,
          },
        )
      }

      it "should set parameters into config" do
        instance.send(:process_information_hash, info_hash, path)
        expect(config[:parameters][:key1]).to eq(1)
        expect(config[:parameters][:key2]).to eq(2)
      end

      it "should load value through resolvers" do
        expect(instance).to receive(:resolve).with(1)
        expect(instance).to receive(:resolve).with(2)
        instance.send(:process_information_hash, info_hash, path)
      end

      context "when parameter is set in config" do
        before { config.set(:parameters, :key1, "VALUE") }

        it "should not overwrite config" do
          instance.send(:process_information_hash, info_hash, path)
          expect(config[:parameters][:key1]).to eq("VALUE")
          expect(config[:parameters][:key2]).to eq(2)
        end
      end
    end

    context "when compile time parameters are set" do
      let(:info_hash) {
        Smash.new(
          :compile_parameters => {
            :key1 => 1,
            :key2 => 2,
          },
        )
      }

      it "should set compile parameters into config" do
        instance.send(:process_information_hash, info_hash, path)
        expect(config[:compile_parameters][:key1]).to eq(1)
        expect(config[:compile_parameters][:key2]).to eq(2)
      end

      it "should load value through resolvers" do
        expect(instance).to receive(:resolve).with(1)
        expect(instance).to receive(:resolve).with(2)
        instance.send(:process_information_hash, info_hash, path)
      end

      context "when compile parameter is set in config" do
        before { config.set(:compile_parameters, :key1, "VALUE") }

        it "should not overwrite config" do
          instance.send(:process_information_hash, info_hash, path)
          expect(config[:compile_parameters][:key1]).to eq("VALUE")
          expect(config[:compile_parameters][:key2]).to eq(2)
        end
      end
    end

    context "with apply stacks set" do
      let(:info_hash) { Smash.new(:apply_stacks => ["stack1"]) }

      it "should add stack name to config apply stack list" do
        instance.send(:process_information_hash, info_hash, path)
        expect(config[:apply_stack]).to include("stack1")
      end

      context "when stack name already exists in config" do
        before { config[:apply_stack] << "stack1" }

        it "should not have duplicate names in apply stack" do
          instance.send(:process_information_hash, info_hash, path)
          expect(config[:apply_stack]).to eq(["stack1"])
        end
      end
    end

    context "with mappings set" do
      let(:info_hash) { Smash.new(:mappings => {:first_key => :first_value}) }

      it "should camel case value in config" do
        instance.send(:process_information_hash, info_hash, path)
        expect(config[:apply_mapping][:first_key]).to eq("FirstValue")
      end
    end

    context "with tags set" do
      let(:info_hash) { Smash.new(:tags => {:tag_key => "value"}) }

      it "should set tags" do
        instance.send(:process_information_hash, info_hash, path)
        expect(config[:options][:tags][:tag_key]).to eq("value")
      end
    end
  end

  describe "#resolve" do
    let(:value) { :value }

    it "should return value when not a hash" do
      expect(instance.send(:resolve, value)).to eq(value)
    end

    context "when value is a hash" do
      let(:value) { {key: "value"} }

      it "should return the given hash" do
        expect(instance.send(:resolve, value)).to eq(value)
      end

      context "when value hash includes resolver name" do
        let(:value) { {key: "value", resolver: resolver_name} }
        let(:resolver_name) { "unknown_test_resolver" }

        context "when resolver is not defined" do
          it "should raise an error" do
            expect { instance.send(:resolve, value) }.to raise_error(NameError)
          end
        end

        context "when resolver is defined" do
          instance_eval("class ::InfraTestResolver < SfnParameters::Resolver; def resolve(v); :resolved; end; end")

          let(:resolver_name) { "infra_test_resolver" }

          it "should resolve value through resolver" do
            expect(instance.send(:resolve, value)).to eq(:resolved)
          end
        end
      end
    end
  end

  describe "#load_resolver" do
    let(:resolver_name) { "test_load_resolver" }
    let(:resolver_class) { double("resolver_class") }
    let(:resolver) { double("resolver") }

    before { allow(resolver_class).to receive(:new).and_return(resolver) }

    it "should memoize based on name" do
      expect(instance).to receive(:memoize).with(resolver_name)
      instance.send(:load_resolver, resolver_name)
    end

    it "should load the resolver" do
      expect(SfnParameters::Resolver).to receive(:detect_resolver).
                                           with(resolver_name).and_return(resolver_class)
      instance.send(:load_resolver, resolver_name)
    end

    it "should not recreate the resolver instance" do
      expect(SfnParameters::Resolver).to receive(:detect_resolver).
                                           with(resolver_name).and_return(resolver_class)
      expect(resolver_class).to receive(:new).and_return(resolver)
      first = instance.send(:load_resolver, resolver_name)
      second = instance.send(:load_resolver, resolver_name)
      expect(first).to be(second)
    end
  end

  describe "#extract_resolver_information" do
    let(:value) { double("value") }

    context "when value is not a hash" do
      it "returns nil for the resolver" do
        r, _ = instance.send(:extract_resolver_information, value)
        expect(r).to be_nil
      end

      it "returns value when not a hash" do
        _, v = instance.send(:extract_resolver_information, value)
        expect(v).to eq(value)
      end
    end

    context "when value is a hash" do
      context "with multiple entries" do
        let(:value) { {key1: 1, key2: 2} }

        it "returns nil for the resolver" do
          r, _ = instance.send(:extract_resolver_information, value)
          expect(r).to be_nil
        end

        it "returns original value" do
          _, v = instance.send(:extract_resolver_information, value)
          expect(v).to eq(value)
        end

        context "and includes a resolver key with known resolver" do
          let(:resolver) { double("resolver") }

          before do
            value[:resolver] = :test_resolver
            allow(instance).to receive(:load_resolver).with("TestResolver").
                                 and_return(resolver)
          end

          it "returns the resolver" do
            r, _ = instance.send(:extract_resolver_information, value)
            expect(r).to eq(resolver)
          end

          it "returns data hash without resolver key" do
            _, d = instance.send(:extract_resolver_information, value)
            expect(d[:key1]).to eq(1)
            expect(d[:key2]).to eq(2)
            expect(d).not_to include(:resolver)
          end
        end

        context "includes a resolver key without known resolver" do
          before do
            value[:resolver] = :test_resolver
            allow(instance).to receive(:load_resolver).with("TestResolver").
                                 and_raise(NameError)
          end

          it "should raise an exception" do
            expect {
              instance.send(:extract_resolver_information, value)
            }.to raise_error(NameError)
          end
        end
      end

      context "with single entry" do
        let(:value) { {key: "value"} }

        context "and no resolver matching key name" do
          before {
            allow(instance).to receive(:load_resolver).with("Key").
                                 and_raise(NameError)
          }

          it "returns nil for the resolver" do
            r, _ = instance.send(:extract_resolver_information, value)
            expect(r).to be_nil
          end

          it "returns original value" do
            _, v = instance.send(:extract_resolver_information, value)
            expect(v).to eq(value)
          end
        end

        context "and resolver matching key name" do
          let(:resolver) { double("resolver") }

          before {
            allow(instance).to receive(:load_resolver).with("Key").
                                 and_return(resolver)
          }

          it "returns the resolver" do
            r, _ = instance.send(:extract_resolver_information, value)
            expect(r).to eq(resolver)
          end

          it "returns the value of the hash" do
            _, d = instance.send(:extract_resolver_information, value)
            expect(d).to eq("value")
          end
        end
      end
    end
  end
end
