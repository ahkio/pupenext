class Keyword::CustomerCategory < Keyword
  has_many :customers, foreign_key: :luokka, primary_key: :selite

  def self.sti_name
    :ASIAKASLUOKKA
  end
end