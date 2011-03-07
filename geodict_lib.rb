# Geodict
# Copyright (C) 2010 Pete Warden <pete@petewarden.com>
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

require 'rubygems'

require 'postgres'
require 'set'

# Some hackiness to include the library script, even if invoked from another directory
require File.join(File.expand_path(File.dirname(__FILE__)), 'geodict_config')

# The main entry point. This function takes an unstructured text string and returns a list of all the
# fragments it could identify as locations, together with lat/lon positions
def find_locations_in_text(text)

  cursor = get_database_connection()

  current_index = text.length-1
  result = []

  setup_countries_cache(cursor)
  setup_regions_cache(cursor)
  
  # This loop goes through the text string in *reverse* order. Since locations in English are typically
  # described with the broadest category last, preceded by more and more specific designations towards
  # the beginning, it simplifies things to walk the string in that direction too
  while current_index>=0 do

    current_word, pulled_index, ignored_skipped = pull_word_from_end(text, current_index)
    lower_word = current_word.downcase
    could_be_country = $countries_cache.has_key?(lower_word)
    could_be_region = $regions_cache.has_key?(lower_word)
      
    if not could_be_country and not could_be_region
      current_index = pulled_index
      next
    end

    # This holds the results of the match function for the final element of the sequence. This lets us
    # optimize out repeated calls to see if the end of the current string is a country for example
    match_cache = {}
    token_result = nil
  
    # These 'token sequences' describe patterns of discrete location elements that we'll look for.
    $token_sequences.each() do |token_sequence|

      # The sequences are specified in the order they'll occur in the text, but since we're walking
      # backwards we need to reverse them and go through the sequence in that order too
      token_sequence = token_sequence.reverse

      # Now go through the sequence and see if we can match up all the tokens in it with parts of
      # the string
      token_result = nil
      token_index = current_index
      token_sequence.each_with_index do |token_name, token_position|

        # The token definition describes how to recognize part of a string as a match. Typical
        # tokens include country, city and region names
        token_definition = $token_definitions[token_name]  
        match_function = token_definition[:match_function]
            
        # This logic optimizes out repeated calls to the same match function
        if token_position == 0 and match_cache.has_key?(token_name)
          token_result = match_cache[token_name]
        else
          # The meat of the algorithm, checks the ending of the current string against the
          # token testing function, eg seeing if it matches a country name
          token_result = send(match_function, cursor, text, token_index, token_result)
          if token_position == 0
            match_cache[token_name] = token_result
          end
        end
          
        if !token_result
          # The string doesn't match this token, so the sequence as a whole isn't a match
          break
        else
          # The current token did match, so move backwards through the string to the start of
          # the matched portion, and see if the preceding words match the next required token
          token_index = token_result[:found_tokens][0][:start_index]-1
        end
      end
        
      # We got through the whole sequence and all the tokens match, so we have a winner!
      if token_result
        current_word, current_index, end_skipped = pull_word_from_end(text, current_index)
        break
      end
    end
        
    if !token_result
      # None of the sequences matched, so back up a word and start over again
      ignored_word, current_index, end_skipped = pull_word_from_end(text, current_index)
    else
      # We found a matching sequence, so add the information to the result
      result.push(token_result)
      found_tokens = token_result[:found_tokens]
      current_index = found_tokens[0][:start_index]-1
    end
  
  end
  
  # Reverse the result so it's in the order that the locations occured in the text
  result.reverse!
  
  return result

end

# Functions that look at a small portion of the text, and try to identify any location identifiers

# Caches the countries and regions tables in memory
$countries_cache = {}

def setup_countries_cache(conn)

  select = 'SELECT * FROM countries'
  hashes = select_as_hashes(conn, select)
    
  hashes.each do |hash|
    last_word = hash['last_word'].downcase
    if !$countries_cache.has_key?(last_word)
      $countries_cache[last_word] = []
    end
    $countries_cache[last_word].push(hash)
  end
  
end

$regions_cache = {}

def setup_regions_cache(conn)

  select = 'SELECT * FROM regions'
  hashes = select_as_hashes(conn, select)
    
  hashes.each do |hash|
    last_word = hash['last_word'].downcase
    if !$regions_cache.has_key?(last_word)
      $regions_cache[last_word] = []
    end
    $regions_cache[last_word].push(hash)
  end

end

# Matches the current fragment against our database of countries
def is_country(conn, text, text_starting_index, previous_result)
        
  current_word = ''
  current_index = text_starting_index
  pulled_word_count = 0
  found_row = nil

  # Walk backwards through the current fragment, pulling out words and seeing if they match
  # the country names we know about
  while pulled_word_count < GeodictConfig::WORD_MAX do
    pulled_word, current_index, end_skipped = pull_word_from_end(text, current_index)
    pulled_word_count += 1
    if current_word == ''
      # This is the first time through, so the full word is just the one we pulled
      current_word = pulled_word
      # Make a note of the real end of the word, ignoring any trailing whitespace
      word_end_index = (text_starting_index-end_skipped)
            
      # We've indexed the locations by the word they end with, so find all of them
      # that have the current word as a suffix
      last_word = pulled_word.downcase
      if !$countries_cache.has_key?(last_word)
        break
      end
      candidate_dicts = $countries_cache[last_word]
            
      name_map = {}
      candidate_dicts.each do |candidate_dict|
        name = candidate_dict['country'].downcase
        name_map[name] = candidate_dict
      end
    else
      current_word = pulled_word+' '+current_word
    end

    # This happens if we've walked backwards all the way to the start of the string
    if current_word == ''
      return nil
    end

    # If the first letter of the name is lower case, then it can't be the start of a country
    # Somewhat arbitrary, but for my purposes it's better to miss some ambiguous ones like this
    # than to pull in erroneous words as countries (eg thinking the 'uk' in .co.uk is a country)
    if current_word[0].chr =~ /[a-z]/
      next
    end
    
    name_key = current_word.downcase
    if name_map.has_key?(name_key)
      found_row = name_map[name_key]
    end

    if found_row
      # We've found a valid country name
      break
    end
    
    if current_index < 0
      # We've walked back to the start of the string
      break
    end
  
  end 
    
  if !found_row 
    # We've walked backwards through the current words, and haven't found a good country match
    return nil
  end
  
  # Were there any tokens found already in the sequence? Unlikely with countries, but for
  # consistency's sake I'm leaving the logic in
  if !previous_result
    current_result = {
      :found_tokens => [],
    }
  else
    current_result = previous_result
  end
                                        
  country_code = found_row['country_code']
  lat = found_row['lat']
  lon = found_row['lon']

  # Prepend all the information we've found out about this location to the start of the :found_tokens
  # array in the result
  current_result[:found_tokens].unshift({
    :type => :COUNTRY,
    :code => country_code,
    :lat => lat,
    :lon => lon,
    :matched_string => current_word,
    :start_index => (current_index+1),
    :end_index => word_end_index 
  })
  
  return current_result

end

# Looks through our database of 2 million towns and cities around the world to locate any that match the
# words at the end of the current text fragment
def is_city(conn, text, text_starting_index, previous_result)
    
  # If we're part of a sequence, then use any country or region information to narrow down our search
  country_code = nil
  region_code = nil
  if previous_result
    found_tokens = previous_result[:found_tokens]
    found_tokens.each do |found_token|
      type = found_token[:type]
      if type == :COUNTRY:
        country_code = found_token[:code]
      elsif type == :REGION:
        region_code = found_token[:code]
      end
    end
  end
    
  current_word = ''
  current_index = text_starting_index
  pulled_word_count = 0
  found_row = nil
  while pulled_word_count < GeodictConfig::WORD_MAX do
    pulled_word, current_index, end_skipped = pull_word_from_end(text, current_index)
    pulled_word_count += 1
        
    if current_word == ''
      current_word = pulled_word
      word_end_index = (text_starting_index-end_skipped)

      select = "SELECT * FROM cities WHERE last_word='"+pulled_word.downcase+"'"
      
      if country_code
        select += " AND country='"+country_code.downcase+"'"
      end
      
      if region_code
        select += " AND region_code='"+region_code.downcase+"'"
      end

      # There may be multiple cities with the same name, so pick the one with the largest population
      select += ' ORDER BY population;'
      
      hashes = select_as_hashes(conn, select)
      
      name_map = {}
      hashes.each do |hash|
        name = hash['city'].downcase
        name_map[name] = hash
      end
    else
      current_word = pulled_word+' '+current_word
    end
    
    if current_word == ''
      return nil
    end
        
    if current_word[0].chr =~ /[a-z]/
      next
    end
    
    name_key = current_word.downcase
    if name_map.has_key?(name_key)
      found_row = name_map[name_key]
    end

    if found_row
      break
    end
    
    if current_index < 0
      break
    end
    
  end
    
  if !found_row
    return nil
  end
    
  if !previous_result
    current_result = {
      :found_tokens => [],
    }
  else
    current_result = previous_result
  end
                                      
  lat = found_row['lat']
  lon = found_row['lon']
                
  current_result[:found_tokens].unshift( {
    :type => :CITY,
    :lat => lat,
    :lon => lon,
    :matched_string => current_word,
    :start_index => (current_index+1),
    :end_index => word_end_index 
  })
    
  return current_result

end

# This looks for sub-regions within countries. At the moment the only values in the database are for US states
def is_region(cursor, text, text_starting_index, previous_result)

  # Narrow down the search by country, if we already have it
  country_code = nil
  if previous_result
    found_tokens = previous_result[:found_tokens]
    found_tokens.each do |found_token|
      type = found_token[:type]
      if type == :COUNTRY
        country_code = found_token[:code]
      end
    end
  end
    
  current_word = ''
  current_index = text_starting_index
  pulled_word_count = 0
  found_row = nil
  while pulled_word_count < GeodictConfig::WORD_MAX do
    pulled_word, current_index, end_skipped = pull_word_from_end(text, current_index)
    pulled_word_count += 1
    if current_word == ''
      current_word = pulled_word
      word_end_index = (text_starting_index-end_skipped)
            
      last_word = pulled_word.downcase
      if !$regions_cache.has_key?(last_word)
        break
      end
      
      all_candidate_dicts = $regions_cache[last_word]
      if country_code
        candidate_dicts = []
        all_candidate_dicts.each do |possible_dict|
          candidate_country = possible_dict['country_code']
          if candidate_country.downcase() == country_code.downcase():
            candidate_dicts.append(possible_dict)
          end
        end
      else
        candidate_dicts = all_candidate_dicts
      end
      
      name_map = {}
      candidate_dicts.each do |candidate_dict|
        name = candidate_dict['region'].downcase
        name_map[name] = candidate_dict
      end
      
    else
      current_word = pulled_word+' '+current_word
    end
    
    if current_word == ''
      return nil
    end

    if current_word[0].chr =~ /[a-z]/
      next
    end

    name_key = current_word.downcase
    if name_map.has_key?(name_key)
      found_row = name_map[name_key]
    end
    
    if found_row
      break
    end
    
    if current_index < 0
      break
    end
    
  end
    
  if !found_row
    return nil
  end
    
  if !previous_result
    current_result = {
      :found_tokens => [],
    }
  else
    current_result = previous_result
  end

  region_code = found_row['region_code']
  lat = found_row['lat']
  lon = found_row['lon']
                
  current_result[:found_tokens].unshift( {
    :type => :REGION,
    :code => region_code,
    :lat => lat,
    :lon => lon,
    :matched_string => current_word,
    :start_index => (current_index+1),
    :end_index=> word_end_index 
  })
    
  return current_result

end

# A special case - used to look for 'at' or 'in' before a possible location word. This helps me be more certain
# that it really is a location in this context. Think 'the New York Times' vs 'in New York' - with the latter
# fragment we can be pretty sure it's talking about a location
def is_location_word(cursor, text, text_starting_index, previous_result)

  current_index = text_starting_index
  current_word, current_index, end_skipped = pull_word_from_end(text, current_index)
  word_end_index = (text_starting_index-end_skipped)
  if current_word == ''
    return nil
  end

  current_word.downcase!
    
  if !GeodictConfig::LOCATION_WORDS.has_key?(current_word)
    return nil
  end

  return previous_result

end

# Utility functions

def get_database_connection

#  begin
    conn = PGconn.connect(GeodictConfig::HOST, GeodictConfig::PORT, '', '', GeodictConfig::DATABASE, GeodictConfig::USER, GeodictConfig::PASSWORD)
    if $DEBUG
      fd = open("/tmp/trace.out","w")
      conn.trace(fd)
    end 
#  rescue PGError
#    printf(STDERR, "Error connecting to database\n")
#    exit(1)
#  end  

  return conn

end

# Characters to ignore when pulling out words
WHITESPACE = " \t'\",.-/\n\r<>".split(//).to_set

$tokenized_words = {}

# Walks backwards through the text from the end, pulling out a single unbroken sequence of non-whitespace
# characters, trimming any whitespace off the end
def pull_word_from_end(text, index, use_cache=true)

  if use_cache and $tokenized_words.has_key?(index)
    return $tokenized_words[index]
  end

  found_word = ''
  current_index = index
  end_skipped = 0
  while current_index>=0 do
    current_char = text[current_index].chr
    current_index -= 1
    
    if WHITESPACE.include?(current_char)
      
      if found_word == ''
        end_skipped += 1
        next
      else
        current_index += 1
        break
      end
    
    end
        
    found_word << current_char
  end
    
  # reverse the result (since we're appending for efficiency's sake)
  found_word.reverse!
    
  result = [found_word, current_index, end_skipped]
  $tokenized_words[index] = result

  return result

end

# Converts the result of an SQL fetch into an associative dictionary, rather than a numerically indexed list
def get_hash_from_row(fields, row)
  d = {}
  
  fields.each_with_index do |field, index|
    value = row[index]
    d[field] = value
  end
  
  return d

end

# Returns the results of the SQL select statement as associative arrays/hashes
def select_as_hashes(conn, select)

  begin

    res = conn.exec('BEGIN')
    res.clear
    res = conn.exec('DECLARE myportal CURSOR FOR '+select)
    res.clear

    res = conn.exec('FETCH ALL in myportal')

    fields = res.fields
    rows = res.result
    
    res = conn.exec('CLOSE myportal')
    res = conn.exec('END')
    
    result = []
    rows.each do |row|
      hash = get_hash_from_row(fields, row)
      result.push(hash)
    end
    
  rescue PGError
    printf(STDERR, conn.error)
    exit(1)
  end  

  return result

end


# Types of locations we'll be looking for
$token_definitions = {
  :COUNTRY => {
    :match_function => :is_country
  },
  :CITY => {
    :match_function => :is_city
  },
  :REGION => {
    :match_function => :is_region
  },
  :LOCATION_WORD => {
    :match_function => :is_location_word
  }
}

# Particular sequences of those location words that give us more confidence they're actually describing
# a place in the text, and aren't coincidental names (eg 'New York Times')
$token_sequences = [
  [ :CITY, :COUNTRY ],
  [ :CITY, :REGION ],
  [ :REGION, :COUNTRY ],
  [ :COUNTRY ],
  [ :LOCATION_WORD, :REGION ], # Regions and cities are too common as words to use without additional evidence
  [ :LOCATION_WORD, :CITY ]
]
