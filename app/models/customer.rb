class Customer < ActiveRecord::Base
  belongs_to :company, foreign_key: :yhtio, primary_key: :yhtio
  belongs_to :terms_of_payment, foreign_key: :maksuehto, primary_key: :tunnus

  default_scope { where.not(laji: %w(P R)) }

  self.table_name = :asiakas
  self.primary_key = :tunnus
  self.record_timestamps = false
end