RSpec.describe EtCcdClient do
  subject(:mod) { described_class }

  it "has a version number" do
    expect(EtCcdClient::VERSION).not_to be nil
  end

  describe ".config" do
    it "returns the config instance" do
      expect(mod.config).to be_an_instance_of(::EtCcdClient::Config)
    end
  end
end
