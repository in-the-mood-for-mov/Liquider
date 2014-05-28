require 'test_helper'

class TestTokens < LiquiderTestCase
  def test_an_identifier_cannot_be_empty
    refute_ident ''
  end

  def test_an_identifier_can_be_composed_of_one_alphabetic_character
    ['a', 'T', 'é', 'λ', 'Ж'].each do |s|
      assert_ident s
    end
  end

  def test_an_identifier_can_be_composed_of_one_underscore
    assert_ident '_'
  end

  def test_an_identifier_cannot_be_composed_of_a_digit_or_punctuation
    ['0', '9', '-', '!', '?'].each do |s|
      refute_ident s
    end
  end

  def test_an_identifier_cannot_start_with_a_digit_or_punctuation
    ['0foo', '9foo', '-foo', '!foo', '?foo'].each do |s|
      refute_ident s
    end
  end

  def test_an_identifer_can_contain_digits_or_hyphens
    ['a1234', 'a-b', 'a-1foo', '_1_-'].each do |s|
      assert_ident s
    end
  end

  def test_an_identifier_can_end_with_a_bang
    ['a!', '_!', 'a1!', 'a-!', 'a1a!'].each do |s|
      assert_ident s
    end
  end

  def test_an_identifier_can_end_with_a_question_mark
    ['a?', '_?', 'a1?', 'a-?', 'a1a?'].each do |s|
      assert_ident s
    end
  end

  def test_an_identifier_cannot_have_a_embedded_bang
    refute_ident 'a!a'
  end

  def test_an_identifier_cannot_have_a_embedded_question_mark
    refute_ident 'a?a'
  end

  private

  def assert_ident(s)
    assert_match_whole_string Liquider::Tokens::Ident.pattern, s
  end

  def refute_ident(s)
    refute_match_whole_string Liquider::Tokens::Ident.pattern, s
  end

  def assert_match_whole_string(pattern, s)
    pattern =~ s
    assert_equal s, $&
  end

  def refute_match_whole_string(pattern, s)
    pattern =~ s
    refute_equal s, $&
  end
end
