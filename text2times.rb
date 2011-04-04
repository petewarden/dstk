# DateExtract
#
# This module takes a chunk of text, and tries to extract dates and times mentioned
# within it. Only works with English-language texts.
#
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

require 'chronic'

T2T_WHITESPACE = '(([ \t.,;]+)|^|$)'
SEPARATOR = '(:|/|-|\\\|)'

def re_string_union(list)
  '('+list.join('|')+')'
end

def re_string_sequence(list)
  '('+list.join(T2T_WHITESPACE)+')'
end

def re_string_separator_sequence(list)
  '('+list.join(SEPARATOR)+')'
end

def t2t_debug_log(message)
  printf(STDERR, "%s\n" % message)
end

# The main entry point. This function takes an unstructured text string and returns a list of all the
# fragments it could identify as dates, along with a Unix timestamp value for each of them.
def text2times(text)

  time = '(('+T2T_WHITESPACE+'at'+T2T_WHITESPACE+')?'+
    '[012]?[0-9]'+
    '((:[0-9][0-9])|(('+T2T_WHITESPACE+')?(am|pm)))'+
    '(:[0-9][0-9])?'+
    '(('+T2T_WHITESPACE+')?(am|pm))?'+
    '(('+T2T_WHITESPACE+')?(GMT|PST|PT|MT|EST|ET|CT))?'+
    '('+T2T_WHITESPACE+'on)?)'

  weekday = re_string_union([ 
    'Monday', 'Mon',
    'Tuesday', 'Tue', 'Tues',
    'Wednesday', 'Wed', 'Weds',
    'Thursday', 'Thu', 'Thur',
    'Friday', 'Fri',
    'Saturday', 'Sat',
    'Sunday', 'Sun',
    'yesterday', 'today', 'tomorrow'
  ])
  
  month = re_string_union([ 
    'January', 'Jan',
    'February', 'Feb',
    'March', 'Mar',
    'April', 'Apr',
    'May',
    'June', 'Jun',
    'July', 'Jul',
    'August', 'Aug',
    'September', 'Sep',
    'October', 'Oct',
    'November', 'Nov',
    'December', 'Dec',
  ])

  monthdaynum = '([0-3]?[0-9])'

  monthday = re_string_union([
    '[0-3]?[0-9](?:st|nd|rd|th)?',
    'First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth', 'Seventh', 'Eighth', 'Ninth',
    'Tenth', 'Eleventh', 'Twelth', 'Thirteenth', 'Fourteenth', 'Fifteenth', 'Sixteenth', 'Seventeenth', 'Eighteenth', 'Nineteenth',
    'Twentieth', 'Twenty.First', 'Twenty.Second', 'Twenty.Third', 'Twenty.Fourth', 'Twenty.Fifth',
    'Twenty.Sixth', 'Twenty.Seventh', 'Twenty.Eighth', 'Twenty.Ninth', 'Thirtieth', 'Thirty.First'
  ])

  monthnumber = '(0?(\d)|([1[0-2]))'

  yearnumber = '((19|20)?\d\d)'
      
  modifier = '('+re_string_union(['next', 'last', 'this', 'before', 'after'])+T2T_WHITESPACE+')?'

  absolute_dates = T2T_WHITESPACE+'('+modifier+re_string_union([
    re_string_sequence([weekday, month, monthday, yearnumber]),         # Monday January 1st, 2011
    re_string_sequence([weekday, monthday, month, yearnumber]),         # Monday 1st January, 2011
    re_string_sequence([month, monthday, yearnumber]),                  # January 1st, 2011
    re_string_sequence([monthday, month, yearnumber]),                  # 1st January, 2011
    re_string_sequence([month, yearnumber]),                            # January 2011
    re_string_separator_sequence([yearnumber, monthnumber, monthdaynum]),# 2010/01/31
    re_string_separator_sequence([yearnumber, monthdaynum, monthnumber]),# 2010/31/01
    re_string_separator_sequence([monthnumber, monthdaynum, yearnumber]),# 01/31/2010
    re_string_separator_sequence([monthdaynum, monthnumber, yearnumber]),# 31/01/2010
  ])+')'+T2T_WHITESPACE
  
  all_dates = T2T_WHITESPACE+'('+modifier+re_string_union([
    re_string_sequence([weekday, month, monthday, yearnumber]),         # Monday January 1st, 2011
    re_string_sequence([weekday, monthday, month, yearnumber]),         # Monday 1st January, 2011
    re_string_sequence([weekday, month, monthday]),                     # Monday January 1st
    re_string_sequence([weekday, monthday, month]),                     # Monday 1st January
    re_string_sequence([month, monthday, yearnumber]),                  # January 1st, 2011
    re_string_sequence([monthday, month, yearnumber]),                  # 1st January, 2011
    re_string_sequence([month, monthday]),                              # January 1st
    re_string_sequence([monthday, month]),                              # 1st January
    re_string_sequence([month, yearnumber]),                            # January 2011
    re_string_sequence([month]),                                        # January
    re_string_sequence([weekday]),                                      # Monday
    re_string_separator_sequence([yearnumber, monthnumber, monthdaynum]),# 2010/01/31
    re_string_separator_sequence([yearnumber, monthdaynum, monthnumber]),# 2010/31/01
    re_string_separator_sequence([monthnumber, monthdaynum, yearnumber]),# 01/31/2010
    re_string_separator_sequence([monthdaynum, monthnumber, yearnumber]),# 31/01/2010
  ])+')'+T2T_WHITESPACE
    
  all_dates_re = Regexp.new(all_dates, Regexp::IGNORECASE)
  absolute_dates_re = Regexp.new(absolute_dates, Regexp::IGNORECASE)
  time_prefix_re = Regexp.new(T2T_WHITESPACE+'('+time+')'+T2T_WHITESPACE+'?$', Regexp::IGNORECASE)
  time_suffix_re = Regexp.new('^'+T2T_WHITESPACE+'?'+'('+time+')'+T2T_WHITESPACE, Regexp::IGNORECASE)

  t2t_debug_log('all_dates = "'+all_dates+'"')
  t2t_debug_log('time_prefix_re = "'+time_prefix_re.to_s+'"')
  t2t_debug_log('time_suffix_re = "'+time_suffix_re.to_s+'"')

  to_remove = Regexp.new(re_string_union([
    '('+T2T_WHITESPACE+'on)',
    '('+T2T_WHITESPACE+'at)',
  ]))
  
  result = []
  index = 0
  stride = 128
  base_time = nil
  while index<text.length do
  
    current_text = text[index..(index+(stride*2))]

    match = all_dates_re.match(current_text)
    if !match
      index += stride
      next
    end

    t2t_debug_log('match = '+match.inspect)
      
    start_index = index+match.begin(3)
    end_index = (index+match.end(3)-1)

    if start_index == 0
      time_prefix_match = false
    else
      prefix = text[index..(start_index-1)]
      time_prefix_match = time_prefix_re.match(prefix)

      t2t_debug_log('prefix = "'+prefix+'"')      
      t2t_debug_log('time_prefix_match = '+time_prefix_match.inspect)
      
    end
  
    if end_index == (text.length-1)
      time_suffix_match = false
    else
      suffix = text[(end_index+1)..(end_index+stride)]
      time_suffix_match = time_suffix_re.match(suffix)

      t2t_debug_log('suffix = "'+suffix+'"')
      t2t_debug_log('time_suffix_match = '+time_suffix_match.inspect)

    end
    
    if time_prefix_match
      start_index = index+time_prefix_match.begin(3)
    elsif time_suffix_match
      end_index = (end_index+time_suffix_match.end(3))
    end
    
    matched_string = text[start_index..end_index]

    t2t_debug_log('matched_string = '+matched_string)

    # Cleanup to work around fragments that confuse Chronic's parsing
    cleaned_string = matched_string.gsub(to_remove, '')
    cleaned_string = cleaned_string.gsub(/(\d?\d)(st|nd|rd|th)/, '\1')
    cleaned_string = cleaned_string.gsub(/(\d)\\(\d)/, '\1/\2')

    t2t_debug_log('cleaned_string = '+cleaned_string)

    span = Chronic.parse(cleaned_string, {:guess => false})
  
    if !span
      t2t_debug_log('Failed to turn into a time - "'+cleaned_string+'"')
      index = [start_index, index].max + 1
      next
    end

    t2t_debug_log('span = '+span.inspect)
  
    is_relative = !absolute_dates_re.match(matched_string)
  
    if !is_relative and !base_time
      base_time = span.begin
    end
    
    output = {
      :time_seconds => span.begin.to_f,
      :time_string => span.begin.to_s,
      :is_relative => is_relative,
      :duration => span.width,
      :matched_string => matched_string,
      :start_index => start_index,
      :end_index => end_index
    }

    t2t_debug_log('output = '+output.inspect)
  
    result.push(output)
    
    index = [end_index+1, index+1].max
  
  end

  # If we found any absolute dates, rework any relative times to be based off that
  if base_time
    
    result.each do |info|
    
      if !info[:is_relative]
        next
      end
      
      matched_string = info[:matched_string]
      cleaned_string = matched_string.gsub(to_remove, '')
      
      span = Chronic.parse(cleaned_string, {:guess => false, :now => base_time})

      info[:time_seconds] = span.begin.to_f
      info[:time_string] = span.begin.to_s
    
    end
  
  end

  result
end
