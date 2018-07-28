require_relative "./base"

describe SfnParameters::Safe do
  describe "#lock" do
    it "should raise NotImplementedError" do
      expect { subject.lock("data") }.to raise_error(NotImplementedError)
    end
  end

  describe "#unlock" do
    it "should raise NotImplementedError" do
      expect { subject.unlock("data") }.to raise_error(NotImplementedError)
    end
  end

  describe ".build" do
    it "should raise argument error when type is unknown" do
      expect {
        described_class.build(type: "unknown")
      }.to raise_error(ArgumentError)
    end

    it "should default to Ssl implementation" do
      expect(SfnParameters::Safe::Ssl).to receive(:new)
      described_class.build
    end
  end
end
