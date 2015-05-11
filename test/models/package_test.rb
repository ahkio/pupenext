require 'test_helper'

class PackageTest < ActiveSupport::TestCase

  def setup
    @p = packages(:first)
  end

  test "assert fixtures are valid" do
    assert @p.valid?
  end

  test "pakkaus cant be empty" do
    @p.pakkaus = ''
    refute @p.valid?
  end

  test "pakkauskuvaus cant be empty" do
    @p.pakkauskuvaus = ''
    refute @p.valid?
  end

  test "dimensions check if parameter is triggered" do
    @p.leveys = ''
    refute @p.valid?

    @p.leveys = 0
    refute @p.valid?

    @p.leveys = 10
    @p.korkeus = 10
    @p.syvyys = 10
    @p.paino = 10
    assert @p.valid?

    @p.korkeus = ''
    refute @p.valid?

    @p.syvyys = ''
    refute @p.valid?

    @p.paino = ''
    refute @p.valid?
  end
end
