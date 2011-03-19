#***********************************************************************************
#
# This module looks for strings that have the characteristics of English-language
# sentences. This means consisting a series of space-separated words, starting with
# a capital letter, ending with a period, etc. It strips out any strings that don't
# match these patterns, and returns the result.
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

def debug_log(message)
#  printf(STDERR, message+"\n")
end

def strip_nonsentences(input, input_settings = { })

  common_short_words = {
    'a' => true,
    'i' => true,
    'ah' => true,
    'an' => true,
    'as' => true,
    'at' => true,
    'ax' => true,
    'be' => true,
    'by' => true,
    'do' => true,
    'ex' => true,
    'go' => true,
    'ha' => true,
    'he' => true,
    'hi' => true,
    'id' => true,
    'if' => true,
    'in' => true,
    'is' => true,
    'it' => true,
    'ma' => true,
    'me' => true,
    'my' => true,
    'no' => true,
    'of' => true,
    'oh' => true,
    'on' => true,
    'or' => true,
    'ox' => true,
    'pa' => true,
    'so' => true,
    'to' => true,
    'uh' => true,
    'um' => true,
    'un' => true,
    'up' => true,
    'us' => true,
    'we' => true
  }

  default_settings = {
      'words_threshold' => 0.75, 
      'sentences_threshold' => 0.5,
      'min_words_in_sentence' => 4,
      'min_sentences_in_paragraph' => 2
  }

  settings = {}
  default_settings.each do |key, value|
    if input_settings.has_key?(key)
      settings[key] = input_settings[key]
    else
      settings[key] = default_settings[key]
    end
  end

  result_lines = []

  lines = input.split("\n")
  lines.each do |line|
    sentences = line.split(/[.?!][^a-zA-Z0-9]/)
        
    # Go through all the 'sentences' and see which ones look valid
    sentences_length = 0
    sentences_matches = 0
    sentences_count = 0
    sentences.each do |sentence|
            
      sentence.strip!
            
      sentences_length += sentence.length
            
      # Is this an empty sentence?
      if sentence.length == 0
        next
      end
                            
      # Does this sentence start with a capital letter?
      first_char_match = sentence.match(/[a-zA-Z]/)
      if !first_char_match
        debug_log(sentence+' - no characters found')
        next
      end
          
      if first_char_match =~ /[a-z]/
        debug_log(sentence+' - first character isn\'t uppercase - '+first_char_match)
        next
      end
      
      # Split sentence by spaces, punctuation  
      words = sentence.split(/[ ]/)
            
      # Is this too short to be a sentence?
      if words.length<settings['min_words_in_sentence']
        debug_log(sentence+' - too few words in sentence: '+words.length.to_s+' - '+words.inspect)
        next
      end
            
      # Go through all the entries and see which ones look like real words
      words_length = 0
      words_matches = 0
      words.each do |word|
        words_length += word.length
            
        # Not all letters?
        if word =~ /[^a-zA-Z\-\'"\.,]/ 
          #'
          debug_log(word+' not all letters')
          next
        end
                    
        # Is it a short word, that isn't common?
        if word.length<3 and not common_short_words.has_key?(word.downcase())
          debug_log(word+' short, and not common')
          next
        end
                    
        words_matches += word.length
      
      end
      
      # No words found?
      if words_length == 0
        debug_log(sentence+' - no words found')
        next
      end
            
      # Were there enough valid words to mark this as a sentence?
      words_ratio = words_matches/(words_length*1.0)
      if words_ratio > settings['words_threshold']
        sentences_matches += sentence.length
        sentences_count += 1
      else
        debug_log(sentence + ' - words ratio too low: '+words_ratio.to_s)
      end
    
    end
      
    result_line = { 'line' => line }
        
    # No sentences found?
    if sentences_length == 0
      result_line['is_sentence'] = false
    else
      # Were there enough valid sentences to mark this line as content?
      sentences_ratio = sentences_matches/(sentences_length*1.0)
      if sentences_ratio > settings['sentences_threshold']
        result_line['is_sentence'] = true
        result_line['sentences_count'] = sentences_count
        result_line['ends_with_period'] = (line =~ /\.[^a-zA-Z]*$/)
      else
        result_line['is_sentence'] = false
        debug_log(line + ' - sentences ratio too low: '+sentences_ratio.to_s)
      end
    end
        
    result_lines.push(result_line)
  
  end

  result = ''
  found_sentences_count = 0
  found_sentences = ''
  result_lines.each do |result_line|
        
    is_sentence = result_line['is_sentence']
        
    if !is_sentence
      if found_sentences_count >= settings['min_sentences_in_paragraph']
        result += found_sentences + "\n"
        debug_log(found_sentences+' - found '+found_sentences_count.to_s)
      else
        debug_log(found_sentences+' - not enough sentences in paragraph: '+found_sentences_count.to_s)
      end
      found_sentences_count = 0
      found_sentences = ''
    else
      sentences_count = result_line['sentences_count']
      has_enough_sentences = sentences_count >= settings['min_sentences_in_paragraph']
      ends_with_period = result_line['ends_with_period']
            
      if has_enough_sentences or ends_with_period
        found_sentences += result_line['line'].strip()+' '
        found_sentences_count += sentences_count
      else
        debug_log(result_line['line']+' - skipping, not enough sentences: '+sentences_count.to_s)
      end
    end

    if found_sentences_count >= settings['min_sentences_in_paragraph']
      result += found_sentences + "\n"
      found_sentences = ''
    end
  end

  return result

end

#input = $stdin.read
#output = strip_nonsentences(input)
#puts output