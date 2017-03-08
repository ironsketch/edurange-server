class Variable

  attr_reader :val, :type

  def initialize(type, val)
    @type = type
    case type
    when "string"
      @val = val
    when "random"
      @val = SecureRandom.hex
    when "openssl_pkey_rsa"
      @val = OpenSSL::PKey::RSA.new(2048).to_pem
    end
  end

end
