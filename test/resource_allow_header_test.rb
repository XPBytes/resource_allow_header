require "test_helper"

class ResourceAllowHeaderTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::ResourceAllowHeader::VERSION
  end
end
