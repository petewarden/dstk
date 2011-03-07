geodict
-------

A simple Python library/command-line tool for pulling location information from unstructured text

Installing
----------

This library uses a large geo-dictionary of countries, regions and cities, all stored in a MySQL database. The source data required is included in this project. To get started:

- Enter the details of your MySQL server and account into geodict_config.py
- Install the MySQLdb module for Python ('easy_install MySQL-python' may do the trick)
- cd into the folder you've unpacked this to, and run ./populate_database.py

This make take several minutes, depending on your machine, since there's over 2 million cities

Running
-------

Once you've done that, give the command-line tool a try:
./geodict.py < testinput.txt

That should produce something like this:
Spain
Italy
Bulgaria
New Zealand
Barcelona, Spain
Wellington New Zealand
Alabama
Wisconsin

Those are the actual strings that the tool picked out as locations. If you want more information
on each of them in a machine-readable format you can specify JSON or CSV:
./geodict.py -f json < testinput.txt
[{"found_tokens": [{"code": "ES", "matched_string": "Spain", "lon": -4.0, "end_index": 4, "lat": 40.0, "type": "COUNTRY", "start_index": 0}]}, {"found_tokens": [{"code": "IT", "matched_string": "Italy", "lon": 12.833299999999999, "end_index": 10, "lat": 42.833300000000001, "type": "COUNTRY", "start_index": 6}]}, {"found_tokens": [{"code": "BG", "matched_string": "Bulgaria", "lon": 25.0, "end_index": 19, "lat": 43.0, "type": "COUNTRY", "start_index": 12}]}, {"found_tokens": [{"code": "NZ", "matched_string": "New Zealand", "lon": 174.0, "end_index": 42, "lat": -41.0, "type": "COUNTRY", "start_index": 32}]}, {"found_tokens": [{"matched_string": "Barcelona", "lon": 2.1833300000000002, "end_index": 52, "lat": 41.383299999999998, "type": "CITY", "start_index": 44}, {"code": "ES", "matched_string": "Spain", "lon": -4.0, "end_index": 59, "lat": 40.0, "type": "COUNTRY", "start_index": 55}]}, {"found_tokens": [{"matched_string": "Wellington", "lon": 174.78299999999999, "end_index": 70, "lat": -41.299999999999997, "type": "CITY", "start_index": 61}, {"code": "NZ", "matched_string": "New Zealand", "lon": 174.0, "end_index": 82, "lat": -41.0, "type": "COUNTRY", "start_index": 72}]}, {"found_tokens": [{"code": "AL", "matched_string": "Alabama", "lon": -86.807299999999998, "end_index": 196, "lat": 32.798999999999999, "type": "REGION", "start_index": 190}]}, {"found_tokens": [{"code": "WI", "matched_string": "Wisconsin", "lon": -89.638499999999993, "end_index": 332, "lat": 44.256300000000003, "type": "REGION", "start_index": 324}]}]

./geodict.py -f csv < testinput.txt
location,type,lat,lon
Spain,country,40.0,-4.0
Italy,country,42.8333,12.8333
Bulgaria,country,43.0,25.0
New Zealand,country,-41.0,174.0
"Barcelona, Spain",city,41.3833,2.18333
Wellington New Zealand,city,-41.3,174.783
Alabama,region,32.799,-86.8073
Wisconsin,region,44.2563,-89.6385

For more of a real-world test, try feeding in the front page of the New York Times:
curl -L "http://newyorktimes.com/" | ./geodict.py
Georgia
Brazil
United States
Iraq
China
Brazil
Pakistan
Afghanistan
Erlanger, Ky
Japan
China
India
India
Ecuador
Ireland
Washington
Iraq
Guatemala

The tool just treats its input as plain text, so in production you'd want to use something like
beautiful soup to strip the tags out of the HTML, but even with messy input like that it's able
to work reasonably well.

Developers
----------

To use this from within your own Python code
import geodict_lib

and then call
locations = geodict_lib.find_locations_in_text(text)

The code itself may be a bit non-idiomatic, I'm still getting up to speed with Python!

Credits
-------

© Pete Warden, 2010 <pete@mailana.com> - http://www.openheatmap.com/

World cities data is from MaxMind: http://www.maxmind.com/app/worldcities

All code is licensed under the GPL V3. For more details on the license see the included gpl.txt
file or go to http://www.gnu.org/licenses/