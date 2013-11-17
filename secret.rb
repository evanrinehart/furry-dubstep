require 'digest/sha1'

module Secret

  def self.hash txt
    Digest::SHA1.hexdigest txt
  end

end
