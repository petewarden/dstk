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

require 'genderfromname'

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
    
    current_text = text[offset..-1]
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

    printf(STDERR, 'Testing "'+first_word+'"'+"\n")
    
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
  
    matched_string = full_match.to_s
    start_index = offset
    end_index = (offset + matched_string.length)

    offset = end_index
  
    printf(STDERR, 'Found "'+matched_string+'"'+"\n")
  
    result.push({
      :gender => gender,
      :title => title,
      :first_name => first_name,
      :surnames => surnames,
      :matched_string => matched_string,
      :start_index => start_index,
      :end_index => end_index
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
    'princess' => 'm',
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
  
  info = gender_from_name(word, 1)
  if !info
    return nil
  end
  
  { :gender => info[:gender] }  
end

#text = open('../cruftstripper/test_data/inputs/cnn.com.html').read()
#output = text2people(text)
#puts output.inspect