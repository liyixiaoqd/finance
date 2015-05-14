class AddIsDigestAuthFieldForAuthorities < ActiveRecord::Migration
  def change
  	add_column :access_authorities,:is_digest_auth,:boolean
  end
end
