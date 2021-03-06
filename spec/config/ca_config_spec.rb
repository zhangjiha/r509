require 'spec_helper'
require 'r509/config/ca_config'
require 'r509/exceptions'

describe R509::Config::CAConfigPool do
  context "defined manually" do
    it "has no configs" do
      pool = R509::Config::CAConfigPool.new({})

      expect(pool["first"]).to be_nil
    end

    it "has one config" do
      config = R509::Config::CAConfig.new(
        :ca_cert => TestFixtures.test_ca_cert,
        :profiles => { "first_profile" => R509::Config::CertProfile.new }
      )

      pool = R509::Config::CAConfigPool.new(
        "first" => config
      )

      expect(pool["first"]).to eq(config)
    end
  end

  context "all configs" do
    context "no configs" do
      before :all do
        @pool = R509::Config::CAConfigPool.new({})
      end

      it "creates" do
        expect(@pool.all).to eq([])
      end

      it "builds yaml" do
        expect(YAML.load(@pool.to_yaml)).to eq({})
      end
    end

    context "one config" do
      before :all do
        @config = R509::Config::CAConfig.new(
          :ca_cert => TestFixtures.test_ca_cert,
          :profiles => { "first_profile" => R509::Config::CertProfile.new }
        )
        @pool = R509::Config::CAConfigPool.new(
          "first" => @config
        )
      end

      it "creates" do
        expect(@pool.all).to eq([@config])
      end

      it "builds yaml" do
        expect(YAML.load(@pool.to_yaml)).to eq("first" => { "ca_cert" => { "cert" => "<add_path>", "key" => "<add_path>" }, "ocsp_start_skew_seconds" => 3600, "ocsp_validity_hours" => 168, "crl_start_skew_seconds" => 3600, "crl_validity_hours" => 168, "crl_md" => "SHA256", "profiles" => { "first_profile" => { "default_md" => "SHA256" } } })
      end
    end

    context "two configs" do
      before :all do
        @config1 = R509::Config::CAConfig.new(
          :ca_cert => TestFixtures.test_ca_cert,
          :profiles => { "first_profile" => R509::Config::CertProfile.new }
        )
        @config2 = R509::Config::CAConfig.new(
          :ca_cert => TestFixtures.test_ca_cert,
          :profiles => { "first_profile" => R509::Config::CertProfile.new }
        )
        @pool = R509::Config::CAConfigPool.new(
          "first" => @config1,
          "second" => @config2
        )
      end

      it "creates" do
        expect(@pool.all.size).to eq(2)
        expect(@pool.all.include?(@config1)).to eq(true)
        expect(@pool.all.include?(@config2)).to eq(true)
      end

      it "builds yaml" do
        expect(YAML.load(@pool.to_yaml)).to eq(
                                                 "first" => {
                                                   "ca_cert" => {
                                                     "cert" => "<add_path>",
                                                     "key" => "<add_path>"
                                                   },
                                                   "ocsp_start_skew_seconds" => 3600,
                                                   "ocsp_validity_hours" => 168,
                                                   "crl_start_skew_seconds" => 3600,
                                                   "crl_validity_hours" => 168,
                                                   "crl_md" => "SHA256",
                                                   "profiles" => {
                                                     "first_profile" => {
                                                       "default_md" => "SHA256"
                                                     }
                                                   }
                                                 },
                                                 "second" => {
                                                   "ca_cert" => {
                                                     "cert" => "<add_path>",
                                                     "key" => "<add_path>"
                                                   },
                                                   "ocsp_start_skew_seconds" => 3600,
                                                   "ocsp_validity_hours" => 168,
                                                   "crl_start_skew_seconds" => 3600,
                                                   "crl_validity_hours" => 168,
                                                   "crl_md" => "SHA256",
                                                   "profiles" => {
                                                     "first_profile" => {
                                                       "default_md" => "SHA256"
                                                     }
                                                   }
                                                 }
                                               )
      end
    end
  end

  context "loaded from YAML" do
    it "should load two configs" do
      pool = R509::Config::CAConfigPool.from_yaml("certificate_authorities", File.read("#{File.dirname(__FILE__)}/../fixtures/config_pool_test_minimal.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures")

      expect(pool.names).to include("test_ca", "second_ca")

      expect(pool["test_ca"]).not_to be_nil
      expect(pool["test_ca"].num_profiles).to eq(0)
      expect(pool["second_ca"]).not_to be_nil
      expect(pool["second_ca"].num_profiles).to eq(0)
    end
  end

end

describe R509::Config::CAConfig do
  before :each do
    @config = R509::Config::CAConfig.new(
      :ca_cert => TestFixtures.test_ca_cert
    )
  end

  subject { @config }

  describe '#crl_validity_hours' do
    subject { super().crl_validity_hours }
    it { is_expected.to eq(168) }
  end

  describe '#ocsp_validity_hours' do
    subject { super().ocsp_validity_hours }
    it { is_expected.to eq(168) }
  end

  describe '#ocsp_start_skew_seconds' do
    subject { super().ocsp_start_skew_seconds }
    it { is_expected.to eq(3600) }
  end

  describe '#num_profiles' do
    subject { super().num_profiles }
    it { is_expected.to eq(0) }
  end

  it "should have the proper CA cert" do
    expect(@config.ca_cert.to_pem).to eq(TestFixtures.test_ca_cert.to_pem)
  end

  it "should have the proper CA key" do
    expect(@config.ca_cert.key.to_pem).to eq(TestFixtures.test_ca_cert.key.to_pem)
  end

  context "to_yaml" do
    it "includes engine stub if in hardware" do
      config = R509::Config::CAConfig.new(:ca_cert => TestFixtures.test_ca_cert)
      expect(config.ca_cert.key).to receive(:in_hardware?).and_return(true)
      expect(YAML.load(config.to_yaml)).to eq("ca_cert" => { "cert" => "<add_path>", "engine" => { :so_path => "<add_path>", :id => "<add_name>" } }, "ocsp_start_skew_seconds" => 3600, "ocsp_validity_hours" => 168, "crl_start_skew_seconds" => 3600, "crl_validity_hours" => 168, "crl_md" => "SHA256")
    end
    it "includes ocsp_cert stub if not nil" do
      config = R509::Config::CAConfig.new(:ca_cert => TestFixtures.test_ca_cert, :ocsp_cert => TestFixtures.test_ca_cert)
      expect(YAML.load(config.to_yaml)).to eq("ca_cert" => { "cert" => "<add_path>", "key" => "<add_path>" }, "ocsp_cert" => { "cert" => "<add_path>", "key" => "<add_path>" }, "ocsp_start_skew_seconds" => 3600, "ocsp_validity_hours" => 168, "crl_start_skew_seconds" => 3600, "crl_validity_hours" => 168, "crl_md" => "SHA256")
    end
    it "includes crl_cert stub if not nil" do
      config = R509::Config::CAConfig.new(:ca_cert => TestFixtures.test_ca_cert, :crl_cert => TestFixtures.test_ca_cert)
      expect(YAML.load(config.to_yaml)).to eq("ca_cert" => { "cert" => "<add_path>", "key" => "<add_path>" }, "crl_cert" => { "cert" => "<add_path>", "key" => "<add_path>" }, "ocsp_start_skew_seconds" => 3600, "ocsp_validity_hours" => 168, "crl_start_skew_seconds" => 3600, "crl_validity_hours" => 168, "crl_md" => "SHA256")
    end
    it "includes ocsp_chain if not nil" do
      config = R509::Config::CAConfig.new(:ca_cert => TestFixtures.test_ca_cert, :ocsp_chain => [OpenSSL::X509::Certificate.new])
      expect(YAML.load(config.to_yaml)).to eq("ca_cert" => { "cert" => "<add_path>", "key" => "<add_path>" }, "ocsp_chain" => "<add_path>", "ocsp_start_skew_seconds" => 3600, "ocsp_validity_hours" => 168, "crl_start_skew_seconds" => 3600, "crl_validity_hours" => 168, "crl_md" => "SHA256")
    end
    it "includes crl_list_file if not nil" do
      config = R509::Config::CAConfig.new(:ca_cert => TestFixtures.test_ca_cert, :crl_list_file => '/some/path')
      expect(YAML.load(config.to_yaml)).to eq("ca_cert" => { "cert" => "<add_path>", "key" => "<add_path>" }, "ocsp_start_skew_seconds" => 3600, "ocsp_validity_hours" => 168, "crl_start_skew_seconds" => 3600, "crl_validity_hours" => 168, "crl_list_file" => "/some/path", "crl_md" => "SHA256")
    end
    it "includes crl_number_file if not nil" do
      config = R509::Config::CAConfig.new(:ca_cert => TestFixtures.test_ca_cert, :crl_number_file => '/some/path')
      expect(YAML.load(config.to_yaml)).to eq("ca_cert" => { "cert" => "<add_path>", "key" => "<add_path>" }, "ocsp_start_skew_seconds" => 3600, "ocsp_validity_hours" => 168, "crl_start_skew_seconds" => 3600, "crl_validity_hours" => 168, "crl_number_file" => "/some/path", "crl_md" => "SHA256")
    end
    it "includes profiles" do
      config = R509::Config::CAConfig.new(:ca_cert => TestFixtures.test_ca_cert)
      profile = R509::Config::CertProfile.new(
        :basic_constraints => { :ca => true }
      )
      config.set_profile("subroot", profile)
      config.set_profile("subroot_also", profile)
      expect(YAML.load(config.to_yaml)).to eq("ca_cert" => { "cert" => "<add_path>", "key" => "<add_path>" }, "ocsp_start_skew_seconds" => 3600, "ocsp_validity_hours" => 168, "crl_start_skew_seconds" => 3600, "crl_validity_hours" => 168, "crl_md" => "SHA256", "profiles" => { "subroot" => { "basic_constraints" => { :ca => true, :critical => true }, "default_md" => "SHA256" }, "subroot_also" => { "basic_constraints" => { :ca => true, :critical => true }, "default_md" => "SHA256" } })
    end
    it "includes defaults" do
      config = R509::Config::CAConfig.new(:ca_cert => TestFixtures.test_ca_cert)
      expect(YAML.load(config.to_yaml)).to eq("ca_cert" => { "cert" => "<add_path>", "key" => "<add_path>" }, "ocsp_start_skew_seconds" => 3600, "ocsp_validity_hours" => 168, "crl_start_skew_seconds" => 3600, "crl_validity_hours" => 168, "crl_md" => "SHA256")
    end
  end

  context "validates data" do
    it "raises an error if you don't pass :ca_cert" do
      expect { R509::Config::CAConfig.new(:crl_validity_hours => 2) }.to raise_error ArgumentError, 'Config object requires that you pass :ca_cert'
    end
    it "raises an error if :ca_cert is not of type R509::Cert" do
      expect { R509::Config::CAConfig.new(:ca_cert => 'not a cert, and not right type') }.to raise_error ArgumentError, ':ca_cert must be of type R509::Cert'
    end
    it "raises an error if :ocsp_cert that is not R509::Cert" do
      expect { R509::Config::CAConfig.new(:ca_cert => TestFixtures.test_ca_cert, :ocsp_cert => "not a cert") }.to raise_error ArgumentError, ':ocsp_cert, if provided, must be of type R509::Cert'
    end
    it "raises an error if :ocsp_cert does not contain a private key" do
      expect { R509::Config::CAConfig.new(:ca_cert => TestFixtures.test_ca_cert, :ocsp_cert => R509::Cert.new(:cert => TestFixtures::TEST_CA_CERT)) }.to raise_error ArgumentError, ':ocsp_cert must contain a private key, not just a certificate'
    end
    it "raises an error if :crl_cert that is not R509::Cert" do
      expect { R509::Config::CAConfig.new(:ca_cert => TestFixtures.test_ca_cert, :crl_cert => "not a cert") }.to raise_error ArgumentError, ':crl_cert, if provided, must be of type R509::Cert'
    end
    it "raises an error if :crl_cert does not contain a private key" do
      expect { R509::Config::CAConfig.new(:ca_cert => TestFixtures.test_ca_cert, :crl_cert => R509::Cert.new(:cert => TestFixtures::TEST_CA_CERT)) }.to raise_error ArgumentError, ':crl_cert must contain a private key, not just a certificate'
    end
  end

  it "loads the config even if :ca_cert does not contain a private key" do
    config = R509::Config::CAConfig.new(:ca_cert => R509::Cert.new(:cert => TestFixtures::TEST_CA_CERT))
    expect(config.ca_cert.subject.to_s).not_to be_nil
  end
  it "returns the correct cert object on #ocsp_cert if none is specified" do
    expect(@config.ocsp_cert).to eq(@config.ca_cert)
  end
  it "returns the correct cert object on #ocsp_cert if an ocsp_cert was specified" do
    ocsp_cert = R509::Cert.new(
      :cert => TestFixtures::TEST_CA_OCSP_CERT,
      :key => TestFixtures::TEST_CA_OCSP_KEY
    )
    config = R509::Config::CAConfig.new(
      :ca_cert => TestFixtures.test_ca_cert,
      :ocsp_cert => ocsp_cert
    )

    expect(config.ocsp_cert).to eq(ocsp_cert)
  end
  it "returns the correct cert object on #crl_cert if none is specified" do
    expect(@config.crl_cert).to eq(@config.ca_cert)
  end
  it "returns the correct cert object on #crl_cert if an crl_cert was specified" do
    crl_cert = R509::Cert.new(
      :cert => TestFixtures::TEST_CA_OCSP_CERT,
      :key => TestFixtures::TEST_CA_OCSP_KEY
    )
    config = R509::Config::CAConfig.new(
      :ca_cert => TestFixtures.test_ca_cert,
      :crl_cert => crl_cert
    )

    expect(config.crl_cert).to eq(crl_cert)
  end
  it "fails to specify a non-Config::CertProfile as the profile" do
    config = R509::Config::CAConfig.new(
      :ca_cert => TestFixtures.test_ca_cert
    )

    expect { config.set_profile("bogus", "not a Config::CertProfile") }.to raise_error TypeError
  end

  it "shouldn't let you specify a profile that's not a Config::CertProfile, on instantiation" do
    expect do
      R509::Config::CAConfig.new(
        :ca_cert => TestFixtures.test_ca_cert,
        :profiles => { "first_profile" => "not a Config::CertProfile" }
      )
    end.to raise_error TypeError
  end

  it "can specify a single profile" do
    first_profile = R509::Config::CertProfile.new

    config = R509::Config::CAConfig.new(
      :ca_cert => TestFixtures.test_ca_cert,
      :profiles => { "first_profile" => first_profile }
    )

    expect(config.profile("first_profile")).to eq(first_profile)
  end

  it "raises an error if you specify an invalid profile" do
    first_profile = R509::Config::CertProfile.new

    config = R509::Config::CAConfig.new(
      :ca_cert => TestFixtures.test_ca_cert,
      :profiles => { "first_profile" => first_profile }
    )

    expect { config.profile("non-existent-profile") }.to raise_error(R509::R509Error, "unknown profile 'non-existent-profile'")
  end

  it "should load YAML" do
    config = R509::Config::CAConfig.from_yaml("test_ca", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures")
    expect(config.crl_validity_hours).to eq(72)
    expect(config.ocsp_validity_hours).to eq(96)
    expect(config.crl_list_file).to match(/list_file$/)
    expect(config.crl_number_file).to match(/number_file$/)
    expect(config.num_profiles).to eq(9)
    expect(config.profile("mds").default_md).to eq("SHA512")
    expect(config.profile("mds").allowed_mds).to eq(['SHA512', 'SHA1'])
    aia = config.profile("aia_cdp").authority_info_access
    expect(aia.ocsp.uris).to eq(['http://ocsp.domain.com'])
    expect(aia.ca_issuers.uris).to eq(['http://www.domain.com/cert.cer'])
    cdp = config.profile("aia_cdp").crl_distribution_points
    expect(cdp.uris).to eq(['http://crl.domain.com/something.crl'])
    expect(config.profile("ocsp_delegate_with_no_check").ocsp_no_check).not_to be_nil
    expect(config.profile("inhibit_policy").inhibit_any_policy.value).to eq(2)
    expect(config.profile("policy_constraints").policy_constraints.require_explicit_policy).to eq(1)
    expect(config.profile("policy_constraints").policy_constraints.inhibit_policy_mapping).to eq(0)
    expect(config.profile("name_constraints").name_constraints).not_to be_nil
  end
  it "loads CRL cert/key from yaml" do
    config = R509::Config::CAConfig.from_yaml("crl_delegate_ca", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test_various.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures")
    expect(config.crl_cert.has_private_key?).to eq(true)
    expect(config.crl_cert.subject.to_s).to eq("/C=US/ST=Illinois/L=Chicago/O=r509 LLC/CN=r509 CRL Delegate")
  end
  it "loads CRL pkcs12 from yaml" do
    config = R509::Config::CAConfig.from_yaml("crl_pkcs12_ca", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test_various.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures")
    expect(config.crl_cert.has_private_key?).to eq(true)
    expect(config.crl_cert.subject.to_s).to eq("/C=US/ST=Illinois/L=Chicago/O=r509 LLC/CN=r509 CRL Delegate")
  end
  it "loads CRL cert/key in engine from yaml" do
    expect { R509::Config::CAConfig.from_yaml("crl_engine_ca", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test_various.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures") }.to raise_error(ArgumentError, "You must supply a key_name with an engine")
  end
  it "loads OCSP cert/key from yaml" do
    config = R509::Config::CAConfig.from_yaml("ocsp_delegate_ca", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test_various.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures")
    expect(config.ocsp_cert.has_private_key?).to eq(true)
    expect(config.ocsp_cert.subject.to_s).to eq("/C=US/ST=Illinois/L=Chicago/O=r509 LLC/CN=r509 OCSP Signer")
  end
  it "loads OCSP pkcs12 from yaml" do
    config = R509::Config::CAConfig.from_yaml("ocsp_pkcs12_ca", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test_various.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures")
    expect(config.ocsp_cert.has_private_key?).to eq(true)
    expect(config.ocsp_cert.subject.to_s).to eq("/C=US/ST=Illinois/L=Chicago/O=r509 LLC/CN=r509 OCSP Signer")
  end
  it "loads OCSP cert/key in engine from yaml" do
    # most of this code path is tested by loading ca_cert engine.
    expect { R509::Config::CAConfig.from_yaml("ocsp_engine_ca", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test_various.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures") }.to raise_error(ArgumentError, "You must supply a key_name with an engine")
  end
  it "loads OCSP chain from yaml" do
    config = R509::Config::CAConfig.from_yaml("ocsp_chain_ca", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test_various.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures")
    expect(config.ocsp_chain.size).to eq(2)
    expect(config.ocsp_chain[0].is_a?(OpenSSL::X509::Certificate)).to eq(true)
    expect(config.ocsp_chain[1].is_a?(OpenSSL::X509::Certificate)).to eq(true)
  end
  it "should load subject_item_policy from yaml (if present)" do
    config = R509::Config::CAConfig.from_yaml("test_ca", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures")
    expect(config.profile("server").subject_item_policy).to be_nil
    expect(config.profile("server_with_subject_item_policy").subject_item_policy.optional).to include("O", "OU")
    expect(config.profile("server_with_subject_item_policy").subject_item_policy.required).to include("CN", "ST", "C")
  end

  it "should load YAML which only has a CA Cert and Key defined" do
    config = R509::Config::CAConfig.from_yaml("test_ca", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test_minimal.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures")
    expect(config.num_profiles).to eq(0)
  end

  it "should load YAML which has CA cert and key with password" do
    expect { R509::Config::CAConfig.from_yaml("password_ca", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test_password.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures") }.to_not raise_error
  end

  it "should load YAML which has a PKCS12 with password" do
    expect { R509::Config::CAConfig.from_yaml("pkcs12_ca", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test_various.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures") }.to_not raise_error
  end

  it "raises error on YAML with pkcs12 and key" do
    expect { R509::Config::CAConfig.from_yaml("pkcs12_key_ca", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test_various.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures") }.to raise_error(ArgumentError, "You can't specify both pkcs12 and key")
  end

  it "raises error on YAML with pkcs12 and cert" do
    expect { R509::Config::CAConfig.from_yaml("pkcs12_cert_ca", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test_various.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures") }.to raise_error(ArgumentError, "You can't specify both pkcs12 and cert")
  end

  it "raises error on YAML with pkcs12 and engine" do
    expect { R509::Config::CAConfig.from_yaml("pkcs12_engine_ca", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test_various.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures") }.to raise_error(ArgumentError, "You can't specify both engine and pkcs12")
  end

  it "loads config with cert and no key (useful in certain cases)" do
    config = R509::Config::CAConfig.from_yaml("cert_no_key_ca", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test_various.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures")
    expect(config.ca_cert.subject.to_s).not_to be_nil
  end

  it "should load YAML which has an engine" do
    fake_engine = double("fake_engine")
    expect(fake_engine).to receive(:is_a?).with(OpenSSL::Engine).and_return(true)
    faux_key = OpenSSL::PKey::RSA.new(TestFixtures::TEST_CA_KEY)
    expect(fake_engine).to receive(:load_private_key).twice.with("key").and_return(faux_key)
    engine = { "SO_PATH" => "path", "ID" => "id" }

    expect(R509::Engine.instance).to receive(:load).with(engine).and_return(fake_engine)

    R509::Config::CAConfig.load_from_hash("ca_cert" => { "cert" => "#{File.dirname(__FILE__)}/../fixtures/test_ca.cer", "engine" => engine, "key_name" => "key" }, "default_md" => "SHA512", "profiles" => {})
  end

  it "should fail if YAML for ca_cert contains engine and key" do
    expect { R509::Config::CAConfig.from_yaml("engine_and_key", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test_engine_key.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures") }.to raise_error(ArgumentError, "You can't specify both key and engine")
  end

  it "should fail if YAML for ca_cert contains engine but no key_name" do
    expect { R509::Config::CAConfig.from_yaml("engine_no_key_name", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test_engine_no_key_name.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures") }.to raise_error(ArgumentError, 'You must supply a key_name with an engine')
  end

  it "should fail if YAML config is null" do
    expect { R509::Config::CAConfig.from_yaml("no_config_here", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures") }.to raise_error(ArgumentError)
  end

  it "should fail if YAML config isn't a hash" do
    expect { R509::Config::CAConfig.from_yaml("config_is_string", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures") }.to raise_error(ArgumentError)
  end

  it "should fail if YAML config doesn't give a root CA directory that's a directory" do
    expect { R509::Config::CAConfig.from_yaml("test_ca", File.read("#{File.dirname(__FILE__)}/../fixtures/config_test.yaml"), :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures/no_directory_here") }.to raise_error(R509::R509Error)
  end

  it "should load YAML from filename" do
    config = R509::Config::CAConfig.load_yaml("test_ca", "#{File.dirname(__FILE__)}/../fixtures/config_test.yaml", :ca_root_path => "#{File.dirname(__FILE__)}/../fixtures")
    expect(config.crl_validity_hours).to eq(72)
    expect(config.ocsp_validity_hours).to eq(96)
    expect(config.num_profiles).to eq(9)
  end

  it "can specify crl_number_file" do
    config = R509::Config::CAConfig.new(
      :ca_cert => TestFixtures.test_ca_cert,
      :crl_number_file => "crl_number_file.txt"
    )
    expect(config.crl_number_file).to eq('crl_number_file.txt')
  end

  it "can specify crl_list_file" do
    config = R509::Config::CAConfig.new(
      :ca_cert => TestFixtures.test_ca_cert,
      :crl_list_file => "crl_list_file.txt"
    )
    expect(config.crl_list_file).to eq('crl_list_file.txt')
  end

end
