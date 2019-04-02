module Encrypt extend ActiveSupport::Concern

	def encrypt(b_data, b_key, iv=nil)
      cipher = OpenSSL::Cipher::AES.new(128, :ECB)
      cipher.encrypt
      cipher.key = b_key
      cipher.iv  = iv if iv.present?
      cipher.update(b_data) << cipher.final
    end

    def encrypt_base64(data, key, iv=nil)
		Base64.strict_encode64(encrypt(data.to_json, Base64.decode64(key)))
    end

    # data, key 传入的为 byte
    def decrypt(b_data, b_key, iv=nil)
      cipher = OpenSSL::Cipher::AES.new(128, :ECB)
      cipher.decrypt
      cipher.key = b_key
      cipher.iv  = iv if iv.present?
      cipher.update(b_data) << cipher.final
    end

    def decrypt_base64(data, key, iv=nil)
    	decrypt(Base64.decode64(data), Base64.decode64(key))
    end

	# SHA 256
	def sha256(message)
		Digest::SHA256.hexdigest(message)
	end

	def sha256_sort(secret, params, split=",")
		result = secret + split

		params.sort.each do |k,v|
			next if v.blank? || k=="content"

			result += "#{k}=#{v}#{split}"
		end

		result += secret

		Rails.logger.info("SHA256_SORT: [#{result}]")
		sha256(result)
	end
end