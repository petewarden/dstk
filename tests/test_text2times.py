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
3 jan 2000        \
17 april 85       \
5/27/1979         \
27/5/1979         \
05/06             \
1979-05-27        \
Friday            \
January 5 at 7pm  \
1979-05-27 05:00:00 \
'

expected_output = [
  {"time_seconds": 1325476800.0, "is_relative": False, "matched_string": "January 1st 2000", "end_index": 19, "time_string": "Sun Jan 01 20:00:00 -0800 2012", "duration": 1, "start_index": 4}, 
  {"time_seconds": 1325793600.0, "is_relative": True, "matched_string": "0  thursday", "end_index": 29, "time_string": "Thu Jan 05 12:00:00 -0800 2012", "duration": 1, "start_index": 19}, 
  {"time_seconds": 1351753200.0, "is_relative": True, "matched_string": "november", "end_index": 47, "time_string": "Thu Nov 01 00:00:00 -0700 2012", "duration": 2595600, "start_index": 40}, 
  {"time_seconds": 1325883600.0, "is_relative": True, "matched_string": "friday 13:00", "end_index": 69, "time_string": "Fri Jan 06 13:00:00 -0800 2012", "duration": 1, "start_index": 58}, 
  {"time_seconds": 1325534400.0, "is_relative": True, "matched_string": "0      mon", "end_index": 78, "time_string": "Mon Jan 02 12:00:00 -0800 2012", "duration": 1, "start_index": 69}, 
  {"time_seconds": 1325889300.0, "is_relative": True, "matched_string": "2:35          friday", "end_index": 99, "time_string": "Fri Jan 06 14:35:00 -0800 2012", "duration": 1, "start_index": 80}, 
  {"time_seconds": 1325318400.0, "is_relative": True, "matched_string": "yesterday", "end_index": 120, "time_string": "Sat Dec 31 00:00:00 -0800 2011", "duration": 86400, "start_index": 112}, 
  {"time_seconds": 1325480400.0, "is_relative": True, "matched_string": "today", "end_index": 134, "time_string": "Sun Jan 01 21:00:00 -0800 2012", "duration": 3600, "start_index": 130}, 
  {"time_seconds": 1325491200.0, "is_relative": True, "matched_string": "tomorrow", "end_index": 155, "time_string": "Mon Jan 02 00:00:00 -0800 2012", "duration": 86400, "start_index": 148}, 
  {"time_seconds": 1325577600.0, "is_relative": True, "matched_string": "this tuesday", "end_index": 177, "time_string": "Tue Jan 03 00:00:00 -0800 2012", "duration": 86400, "start_index": 166}, 
  {"time_seconds": 1325376000.0, "is_relative": True, "matched_string": "yesterday at 4:00", "end_index": 200, "time_string": "Sat Dec 31 16:00:00 -0800 2011", "duration": 1, "start_index": 184}, 
  {"time_seconds": 1325275200.0, "is_relative": True, "matched_string": "0 last friday", "end_index": 212, "time_string": "Fri Dec 30 12:00:00 -0800 2011", "duration": 1, "start_index": 200}, 
  {"time_seconds": 1325563200.0, "is_relative": True, "matched_string": " at 20:00 tomorrow", "end_index": 230, "time_string": "Mon Jan 02 20:00:00 -0800 2012", "duration": 1, "start_index": 213}, 
  {"time_seconds": 1325817900.0, "is_relative": True, "matched_string": " at 6:45pm January 5", "end_index": 250, "time_string": "Thu Jan 05 18:45:00 -0800 2012", "duration": 1, "start_index": 231}, 
  {"time_seconds": 1356483600.0, "is_relative": True, "matched_string": "5         dec 25", "end_index": 265, "time_string": "Tue Dec 25 17:00:00 -0800 2012", "duration": 1, "start_index": 250}, 
  {"time_seconds": 1338163200.0, "is_relative": True, "matched_string": "5            may 27", "end_index": 283, "time_string": "Sun May 27 17:00:00 -0700 2012", "duration": 1, "start_index": 265}, 
  {"time_seconds": 1159686000.0, "is_relative": True, "matched_string": "October 2006", "end_index": 307, "time_string": "Sun Oct 01 00:00:00 -0700 2006", "duration": 2682000, "start_index": 296}, 
  {"time_seconds": 1349528400.0, "is_relative": True, "matched_string": "6      oct 06", "end_index": 319, "time_string": "Sat Oct 06 06:00:00 -0700 2012", "duration": 1, "start_index": 307}, 
  {"time_seconds": 1325599200.0, "is_relative": True, "matched_string": "6            jan 3", "end_index": 336, "time_string": "Tue Jan 03 06:00:00 -0800 2012", "duration": 1, "start_index": 319}, 
  {"time_seconds": 1328155800.0, "is_relative": True, "matched_string": "2010        february", "end_index": 357, "time_string": "Wed Feb 01 20:10:00 -0800 2012", "duration": 1, "start_index": 338}, 
  {"time_seconds": 946947600.0, "is_relative": False, "matched_string": "3 jan 2000        17", "end_index": 387, "time_string": "Mon Jan 03 17:00:00 -0800 2000", "duration": 1, "start_index": 368}, 
  {"time_seconds": 1333893600.0, "is_relative": True, "matched_string": "7 april 8", "end_index": 395, "time_string": "Sun Apr 08 07:00:00 -0700 2012", "duration": 1, "start_index": 387}, 
  {"time_seconds": 296697600.0, "is_relative": False, "matched_string": "27/5/1979         05", "end_index": 441, "time_string": "Sun May 27 17:00:00 -0700 1979", "duration": 1, "start_index": 422}, 
  {"time_seconds": 296636400.0, "is_relative": False, "matched_string": "1979-05-27", "end_index": 467, "time_string": "Sun May 27 00:00:00 -0700 1979", "duration": 86400, "start_index": 458}, 
  {"time_seconds": 1325818800.0, "is_relative": True, "matched_string": "January 5 at 7pm", "end_index": 509, "time_string": "Thu Jan 05 19:00:00 -0800 2012", "duration": 1, "start_index": 494}, 
  {"time_seconds": 296636400.0, "is_relative": False, "matched_string": "1979-05-27", "end_index": 521, "time_string": "Sun May 27 00:00:00 -0700 1979", "duration": 86400, "start_index": 512}
]


actual_output = dstk.text2times(test_input)

print json.dumps(actual_output)