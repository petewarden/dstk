#!/usr/bin/env python
#
# A unit test for the text2times module

import dstk
import json

dstk = dstk.DSTK()

test_input = '    \
January 1st 2000  \
thursday          \
november          \
friday 13:00      \
mon 2:35          \
friday 1pm        \
yesterday         \
today             \
tomorrow          \
this tuesday      \
yesterday at 4:00 \
last friday at 20:00 \
tomorrow at 6:45pm \
January 5         \
dec 25            \
may 27th          \
October 2006      \
oct 06            \
jan 3 2010        \
february 14, 2004 \
3 jan 2007        \
17 april 85       \
5/27/1979         \
27/5/1979         \
05/06             \
1979-05-27        \
Friday            \
January 5 at 7pm  \
1979-05-27 05:00:00 \
1976\\05\\19        \
'

expected_output = [
  {"time_seconds": 1325476800.0, "is_relative": False, "matched_string": "January 1st 2000", "end_index": 19, "time_string": "Sun Jan 01 20:00:00 -0800 2012", "duration": 1, "start_index": 4}, 
  {"time_seconds": 1302159600.0, "is_relative": True, "matched_string": "thursday", "end_index": 29, "time_string": "Thu Apr 07 00:00:00 -0700 2011", "duration": 86400, "start_index": 22}, 
  {"time_seconds": 1320130800.0, "is_relative": True, "matched_string": "november", "end_index": 47, "time_string": "Tue Nov 01 00:00:00 -0700 2011", "duration": 2595600, "start_index": 40}, 
  {"time_seconds": 1302292800.0, "is_relative": False, "matched_string": "friday 13:00", "end_index": 69, "time_string": "Fri Apr 08 13:00:00 -0700 2011", "duration": 1, "start_index": 58}, 
  {"time_seconds": 1301952900.0, "is_relative": True, "matched_string": "mon 2:35", "end_index": 83, "time_string": "Mon Apr 04 14:35:00 -0700 2011", "duration": 1, "start_index": 76}, 
  {"time_seconds": 1302292800.0, "is_relative": True, "matched_string": "friday 1pm", "end_index": 103, "time_string": "Fri Apr 08 13:00:00 -0700 2011", "duration": 1, "start_index": 94}, 
  {"time_seconds": 1301727600.0, "is_relative": True, "matched_string": "yesterday", "end_index": 120, "time_string": "Sat Apr 02 00:00:00 -0700 2011", "duration": 86400, "start_index": 112}, 
  {"time_seconds": 1301864400.0, "is_relative": True, "matched_string": "today", "end_index": 134, "time_string": "Sun Apr 03 14:00:00 -0700 2011", "duration": 36000, "start_index": 130}, 
  {"time_seconds": 1301900400.0, "is_relative": True, "matched_string": "tomorrow", "end_index": 155, "time_string": "Mon Apr 04 00:00:00 -0700 2011", "duration": 86400, "start_index": 148}, 
  {"time_seconds": 1301986800.0, "is_relative": True, "matched_string": "this tuesday", "end_index": 177, "time_string": "Tue Apr 05 00:00:00 -0700 2011", "duration": 86400, "start_index": 166}, 
  {"time_seconds": 1301785200.0, "is_relative": True, "matched_string": "yesterday at 4:00", "end_index": 200, "time_string": "Sat Apr 02 16:00:00 -0700 2011", "duration": 1, "start_index": 184}, 
  {"time_seconds": 1301713200.0, "is_relative": False, "matched_string": "last friday at 20:00", "end_index": 221, "time_string": "Fri Apr 01 20:00:00 -0700 2011", "duration": 1, "start_index": 202}, 
  {"time_seconds": 1301967900.0, "is_relative": True, "matched_string": "tomorrow at 6:45pm", "end_index": 240, "time_string": "Mon Apr 04 18:45:00 -0700 2011", "duration": 1, "start_index": 223}, 
  {"time_seconds": 1325750400.0, "is_relative": True, "matched_string": "January 5", "end_index": 250, "time_string": "Thu Jan 05 00:00:00 -0800 2012", "duration": 86400, "start_index": 242}, 
  {"time_seconds": 1324800000.0, "is_relative": False, "matched_string": "dec 25", "end_index": 265, "time_string": "Sun Dec 25 00:00:00 -0800 2011", "duration": 86400, "start_index": 260}, 
  {"time_seconds": 1306479600.0, "is_relative": True, "matched_string": "may 27th", "end_index": 285, "time_string": "Fri May 27 00:00:00 -0700 2011", "duration": 86400, "start_index": 278}, 
  {"time_seconds": 1159686000.0, "is_relative": False, "matched_string": "October 2006", "end_index": 307, "time_string": "Sun Oct 01 00:00:00 -0700 2006", "duration": 2682000, "start_index": 296}, 
  {"time_seconds": 1317884400.0, "is_relative": False, "matched_string": "oct 06", "end_index": 319, "time_string": "Thu Oct 06 00:00:00 -0700 2011", "duration": 86400, "start_index": 314}, 
  {"time_seconds": 1262505600.0, "is_relative": False, "matched_string": "jan 3 2010", "end_index": 341, "time_string": "Sun Jan 03 00:00:00 -0800 2010", "duration": 86400, "start_index": 332}, 
  {"time_seconds": 1076799600.0, "is_relative": False, "matched_string": "february 14, 2004 3", "end_index": 368, "time_string": "Sat Feb 14 15:00:00 -0800 2004", "duration": 1, "start_index": 350}, 
  {"time_seconds": 482572800.0, "is_relative": False, "matched_string": "17 april 85", "end_index": 396, "time_string": "Wed Apr 17 00:00:00 -0800 1985", "duration": 86400, "start_index": 386}, 
  {"time_seconds": 296636400.0, "is_relative": False, "matched_string": "5/27/1979", "end_index": 412, "time_string": "Sun May 27 00:00:00 -0700 1979", "duration": 86400, "start_index": 404}, 
  {"time_seconds": 296636400.0, "is_relative": False, "matched_string": "27/5/1979", "end_index": 430, "time_string": "Sun May 27 00:00:00 -0700 1979", "duration": 86400, "start_index": 422}, 
  {"time_seconds": 1146466800.0, "is_relative": False, "matched_string": "05/06", "end_index": 444, "time_string": "Mon May 01 00:00:00 -0700 2006", "duration": 2678400, "start_index": 440}, 
  {"time_seconds": 296636400.0, "is_relative": False, "matched_string": "1979-05-27", "end_index": 467, "time_string": "Sun May 27 00:00:00 -0700 1979", "duration": 86400, "start_index": 458}, 
  {"time_seconds": 1325818800.0, "is_relative": True, "matched_string": "January 5 at 7pm", "end_index": 509, "time_string": "Thu Jan 05 19:00:00 -0800 2012", "duration": 1, "start_index": 494}, 
  {"time_seconds": 296654400.0, "is_relative": False, "matched_string": "1979-05-27 05:00:00", "end_index": 530, "time_string": "Sun May 27 05:00:00 -0700 1979", "duration": 1, "start_index": 512}, 
  {"time_seconds": 201337200.0, "is_relative": False, "matched_string": "1976\\05\\19", "end_index": 541, "time_string": "Wed May 19 00:00:00 -0700 1976", "duration": 86400, "start_index": 532}
]

actual_output = dstk.text2times(test_input)

if len(expected_output) != len(actual_output):
  print('Expected '+str(len(expected_output))+' items, found '+str(len(actual_output)))
  exit(1)

for index, actual_item in enumerate(actual_output):
  expected_item = expected_output[index]
  if actual_item['time_seconds'] != expected_item['time_seconds']:
    print json.dumps(actual_output)
    print('Mismatch at item #'+str(index))
    exit(1)
    
print 'text2times test passed'