require 'spec_helper'

include Liquider

RSpec::Matchers.define :parse_to do |token_type|
  match do |source|
    string_scanner = StringScanner.new(source)
    string_scanner.scan(token_type.pattern) && string_scanner.eos?
  end
end

describe Tokens::IdentToken do
  it 'cannot be empty' do
    expect('').not_to parse_to(Tokens::IdentToken)
  end

  it 'can be composed of a single alphabetic character' do
    ['a', 'T', 'é', 'λ', 'Ж'].each do |s|
      expect(s).to parse_to(Tokens::IdentToken)
    end
  end

  it 'can be composed of a single underscore' do
    expect('_').to parse_to(Tokens::IdentToken)
  end

  it 'cannot be composed of a digit or punctuation' do
    ['0', '9', '-', '!', '?'].each do |s|
      expect(s).not_to parse_to(Tokens::IdentToken)
    end
  end

  it 'cannot start with a digit or punctuation' do
    ['0foo', '9foo', '-foo', '!foo', '?foo'].each do |s|
      expect(s).not_to parse_to(Tokens::IdentToken)
    end
  end

  it 'can contain digits or hyphens' do
    ['a1234', 'a-b', 'a-1foo', '_1_-'].each do |s|
      expect(s).to parse_to(Tokens::IdentToken)
    end
  end

  it 'can end with a bang' do
    ['a!', '_!', 'a1!', 'a-!', 'a1a!'].each do |s|
      expect(s).to parse_to(Tokens::IdentToken)
    end
  end

  it 'can end with a question mark' do
    ['a?', '_?', 'a1?', 'a-?', 'a1a?'].each do |s|
      expect(s).to parse_to(Tokens::IdentToken)
    end
  end

  it 'cannot have a embedded bang' do
    expect('a!a').not_to parse_to(Tokens::IdentToken)
  end

  it 'cannot have a embedded question mark' do
    expect('a?a').not_to parse_to(Tokens::IdentToken)
  end
end
