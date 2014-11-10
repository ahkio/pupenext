class SumLevel < ActiveRecord::Base
  belongs_to :company, foreign_key: :yhtio, primary_key: :yhtio

  self.table_name = :taso
  self.primary_key = :tunnus
  self.inheritance_column = :tyyppi
  self.abstract_class = true

  validates :taso, presence: true
  validates :nimi, presence: true
  validates :tyyppi, inclusion: { in: %w[S A U B] }
  #allow blank allows empty string and nil, custom validation for nil is implemented
  validates :kumulatiivinen, inclusion: { in: ["", "X"] }
  validates :taso, uniqueness: { scope: :tyyppi, message: "one taso per type" }
  validate :does_not_contain_char
  validate :summattava_tasos_in_db_and_correct_type
  validate :kumulatiivinen_not_nil

  def sum_level_name
    "#{taso} #{nimi}"
  end

  private
    def self.sum_levels
      {
        S: "SumLevel::Internal",
        U: "SumLevel::External",
        A: "SumLevel::Vat",
        B: "SumLevel::Profit",
      }
    end

    # This functions purpose is to return the child class name.
    # Aka. it should allways return .constantize
    # This function is called from   persistence.rb function: instantiate
    #                             -> inheritance.rb function: discriminate_class_for_record
    # This is the reason we need to map the db column with correct child class in this model
    # type_name = "S", type_name = "U" ...
    def self.find_sti_class(taso_value)
      sum_levels[taso_value.to_sym].constantize
    end

    def does_not_contain_char
      errors.add :taso, "can not contain Ö" if taso.to_s.include? "Ö"
    end

    def summattava_tasos_in_db_and_correct_type
      summattavat_tasot = summattava_taso.split ","
      klass = self.class

      existing_tasos = klass.where(taso: summattavat_tasot)

      same_count = (existing_tasos.count == summattavat_tasot.count)
      err = "summattava_taso needs to be in db and same type"
      errors.add :summattava_taso, err unless same_count
    end

    def kumulatiivinen_not_nil
      errors.add :base, "Kumulatiivinen can not be nil" if kumulatiivinen.nil?
    end
end
