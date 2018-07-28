require_relative "../base"

describe SfnParameters::Safe::Ssl do
  let(:key) { "TEST_KEY" }
  let(:salt) { "TEST_SALT" }
  let(:subject) { described_class.new(key: key, salt: salt) }

  it "should have key set" do
    expect(subject.arguments[:key]).to eq(key)
  end

  it "should have salt set" do
    expect(subject.arguments[:salt]).to eq(salt)
  end

  describe "#new" do
    context "when key is unset" do
      let(:key) { nil }

      it "should raise an ArgumentError" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context "when salt is unset" do
      let(:salt) { nil }

      it "should generate a random salt" do
        expect(subject.arguments[:salt]).to be_a(String)
      end
    end
  end

  describe "#lock" do
    let(:data) { "TEST_DATA" }
    let(:lock) { subject.lock(data) }

    it "should return a Hash result" do
      expect(lock).to be_a(Hash)
    end

    it "should include base64 encoded salt" do
      expect(lock[:salt]).to eq(
        Base64.urlsafe_encode64(salt)
      )
    end

    it "should set type of safe used" do
      expect(lock[:sfn_parameters_lock]).to eq("ssl")
    end

    it "should include cipher used" do
      expect(lock[:cipher]).to eq(described_class.const_get(:DEFAULT_CIPHER))
    end

    it "should base64 encode locked value" do
      expect(Base64.urlsafe_decode64(lock[:content])).to be_a(String)
    end

    it "should encrypt locked value" do
      expect(Base64.urlsafe_decode64(lock[:content])).not_to eq(data)
    end
  end

  describe "#unlock" do
    let(:data) { "TEST_DATA" }

    it "should properly unlock locked data" do
      locked = subject.lock(data)
      expect(Base64.urlsafe_decode64(locked[:content])).not_to eq(data)
      expect(subject.unlock(locked)).to eq(data)
    end

    context "with missing content" do
      it "should raise an ArgumentError" do
        locked = subject.lock(data)
        locked.delete(:content)
        expect { subject.unlock(locked) }.to raise_error(ArgumentError)
      end
    end

    context "with missing iv" do
      it "should raise an ArgumentError" do
        locked = subject.lock(data)
        locked.delete(:iv)
        expect { subject.unlock(locked) }.to raise_error(ArgumentError)
      end
    end

    context "with missing salt" do
      it "should raise an ArgumentError" do
        locked = subject.lock(data)
        locked.delete(:salt)
        expect { subject.unlock(locked) }.to raise_error(ArgumentError)
      end
    end
  end
end
