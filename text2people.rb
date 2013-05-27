#***********************************************************************************
#
# All code (C) Pete Warden, 2011
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#***********************************************************************************

require 'rubygems' if RUBY_VERSION < '1.9'

require 'csv'
require 'json'

# Some hackiness to include the library script, even if invoked from another directory
require File.join(File.expand_path(File.dirname(__FILE__)), 'dstk_config')
require File.join(File.expand_path(File.dirname(__FILE__)), 'geodict_lib')

require 'genderfromname'

CURRENT_YEAR = Time.now.year

$surnames_map = nil

def debug_log(message)
#  begin
#    printf(STDERR, "%s\n" % message.inspect)
#  rescue
#    printf(STDERR, "Error trying to print debug output")
#  end
end

# This function scans through the text, and tries to pull out words that look like the
# names of people. It looks for a series of capitalized words, and then examines the
# first to see if it's a common first name, or title.
def text2people(text)

  two_words = /^([A-Z][a-z]*)\.?\s([A-Z]('[A-Z])?[a-z]+)/
  three_words = /^([A-Z][a-z]*)\.?\s([A-Z][a-z]*)\.?\s([A-Z]('[A-Z])?[a-z]+)/
  four_words = /^([A-Z][a-z]*)\.?\s([A-Z][a-z]*)\.?\s([A-Z][a-z]*)\.?\s([A-Z]('[A-Z])?[a-z]+)/ #'
  
  text_length = text.length
  offset = 0
  result = []
  while offset < text_length do
    current_char = text[offset].chr
    if current_char =~ /[^A-Z]/
      debug_log('"'+current_char+'" is not an upper-case letter, skipping')
      offset += 1
      next
    end
    
    current_text = text[offset..(offset+300)]
    four_match = four_words.match(current_text)
    three_match = three_words.match(current_text)
    two_match = two_words.match(current_text)

    if four_match
      debug_log('Matched four words')
      first_word = four_match[1]
      remaining_words = [four_match[2], four_match[3], four_match[4]]
      full_match = four_match
    elsif three_match
      debug_log('Matched three words')
      first_word = three_match[1]
      remaining_words = [three_match[2], three_match[3]]
      full_match = three_match    
    elsif two_match
      debug_log('Matched two words')
      first_word = two_match[1]
      remaining_words = [two_match[2]]
      full_match = two_match    
    else
      debug_log('No match found, skipping')
      offset += 1
      next
    end
  
    title_match = match_title(first_word)
    first_name_match = match_first_name(first_word)
    $stderr.puts "first_word=#{first_word}"
    if first_name_match
      $stderr.puts "first_name_match=#{first_name_match.to_json}"
    end

    if !title_match and !first_name_match
      debug_log('"'+first_word+'" doesn\'t match a first name or title, skipping')
      offset += first_word.length+1
      next
    end
  
    if title_match
      gender = title_match[:gender]
      title = title_match[:title]
      if remaining_words.length == 1
        first_name = ''
        surnames = remaining_words[0]
      else
        first_name = remaining_words[0]
        surnames = remaining_words[1..-1].join(' ')
      end
    elsif first_name_match
      gender = first_name_match[:gender]
      title = ''
      first_name = first_word
      surnames = remaining_words[0..-1].join(' ')
    end

    if first_name_match
      likely_age = first_name_match[:age]
    else
      likely_age = nil
    end

    ethnicity = get_ethnicity_from_last_name(surnames.split(' ').last)

    matched_string = full_match.to_s
    start_index = offset
    end_index = (offset + matched_string.length)

    offset = end_index

    result.push({
      :gender => gender,
      :title => title,
      :first_name => first_name,
      :surnames => surnames,
      :matched_string => matched_string,
      :start_index => start_index,
      :end_index => end_index,
      :ethnicity => ethnicity,
      :likely_age => likely_age
    })

  end

  result
  
end

def match_title(word)
  titles = {
    'mr' => 'm',
    'mrs' => 'f',
    'miss' => 'f',
    'ms' => 'f',
    'dr' => 'u',
    'doctor' => 'u',
    'reverend' => 'u',
    'bishop' => 'u',
    'archbishop' => 'u',
    'lord' => 'm',
    'sir' => 'm',
    'lady' => 'f',
    'madame' => 'f',
    'professor' => 'u',
    'colonel' => 'u',
    'major' => 'u',
    'lieutenant' => 'u',
    'private' => 'u',
    'admiral' => 'u',
    'president' => 'u',
    'ceo' => 'u',
    'cfo' => 'u',
    'cto' => 'u',
    'king' => 'm',
    'prince' => 'm',
    'princess' => 'f',
  }

  title = word.downcase

  if !titles.has_key?(title)
    debug_log('"'+title+'" not in titles, skipping')
    return nil
  end

  gender = titles[title]

  { :title => title, :gender => gender }
end

def match_first_name(word)
  if word.length<2
    return nil
  end
  
  # A bit arbitrary, but these listed names show up in headlines a lot
  blacklist = {
    'Will' => true,
    'Asia' => true
  }
  if blacklist.has_key?(word)
    return nil
  end

  result = nil
  heuristic_info = gender_from_name(word, 1)
  if heuristic_info
    result = { :gender => heuristic_info[:gender] }
  end

  select = "SELECT * FROM first_names WHERE name='#{PGconn.escape(word.downcase)}';"
  rows = select_as_hashes(select, DSTKConfig::NAMES_DATABASE)
  if rows and rows.length > 0
    row = rows[0]
    count = row['count'].to_i
    male_percentage = row['male_percentage'].to_f
    most_popular_year = row['most_popular_year'].to_i
    earliest_common_year = row['earliest_common_year'].to_i
    latest_common_year = row['latest_common_year'].to_i
    year_percentages = row['year_percentages'].split('_').map do |i| i.to_f end
    if !result then result = {} end
    if !result.has_key?(:gender)
      if male_percentage > 0.5
        result[:gender] = 'm'
      else
        result[:gender] = 'f'
      end
    end
    result[:age] = CURRENT_YEAR - most_popular_year
    result[:year_percentages] = year_percentages
    result[:year_percentages_start_year] = 1880
  end

  result

end

def get_ethnicity_from_last_name(last_name)
  select = "SELECT * FROM ethnicity_of_surnames WHERE name='#{PGconn.escape(last_name.upcase)}';"
  rows = select_as_hashes(select, DSTKConfig::NAMES_DATABASE)
  if !rows or rows.length < 1 then return nil end
  row = rows[0]
  rank = row['rank'].to_i
  percentage_of_total = row['prop100k'].to_f / 1000.0
  percentage_white = row['pctwhite'].to_f
  percentage_black = row['pctblack'].to_f
  percentage_asian_or_pacific_islander = row['pctapi'].to_f
  percentage_american_indian_or_alaska_native = row['pctaian'].to_f
  percentage_two_or_more = row['pct2prace'].to_f
  percentage_hispanic = row['pcthispanic'].to_f
  {
    :rank => rank,
    :percentage_of_total => percentage_of_total,
    :percentage_white => percentage_white,
    :percentage_black => percentage_black,
    :percentage_asian_or_pacific_islander => percentage_asian_or_pacific_islander,
    :percentage_american_indian_or_alaska_native => percentage_american_indian_or_alaska_native,
    :percentage_two_or_more => percentage_two_or_more,
    :percentage_hispanic => percentage_hispanic,
  }
end

if __FILE__ == $0
  test_text = <<-TEXT
Elvis Presley
Something else that's not a name
Pete Warden, blah blah
Tony Blair
Samuel L Jackson
David Aceveda
Henry Martinez
TEXT

  test_text.each_line do |line|
    output = text2people(line)
    puts line
    if output
      puts JSON.pretty_generate(output)
    end
    puts '************'
  end

end