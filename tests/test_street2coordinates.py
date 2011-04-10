#!/usr/bin/env python
#
# A unit test for the text2times module

import dstk
import json

dstk = dstk.DSTK()

test_input = [
  '2543 Graystone Pl, Simi Valley, CA 93065',
  '3865 21st St, Boulder, CO 80304',
  '400 Duboce Ave #208, San Francisco, CA 94117',
  '3 The Broadway, Cambridge. CB1 3AH',
  '261-263 Newmarket Road, Cambridge. CB5 8JE',
  '23 Magdalene Street, Cambridge. CB3 0AF',
  'Hardwick Street, Cambridge. CB3 9JA',
  '139-143 Milton Road, Cambridge. CB4 1XE',
  '5 Arbury Court, Cambridge. CB4 2JQ',
  'Addenbrookes Hosp, Hills Rd, Cambridge. CB2 2QQ',
  '5 Anstey Way, Trumpington, Cambridge. CB2 9JE',
  '70 Division Street, Sheffield. S1 4GF',
  '35 Surrey Street, Sheffield. S1 2LG',
  '143 Castle Market, Sheffield. S1 2AF',
  '142 Castle Market, Sheffield. S1 2AF',
  '309-311 Ecclesall Road, Sheffield. S11 8NX',
  '472 Glossop Road, Sheffield. S10 2QA',
  '269 Fulwood Rd, S10. S10 3BD',
  '326 Abbeydale Road, Sheffield. S7 1FN',
  '363 Sharrow Vale Road, Sheffield. S11 8ZG',
  '6 Cathedral Walk Cardinal Place, London. SW1E 5JH',
  '70 Rochester Rw, London. SW1P 1JU',
  'Victoria Station, London. SW1V 1JY',
  'Victoria Station, London. SW1V 1JT',
  '51 Warwick Way, London. SW1V 1QS',
  '59 Ebury Street, London. SW1W 0NZ',
  '26 Denbigh Street, London. SW1V 2ER',
  '23 Churton Street, London. SW1V 2LY',
  '72 Eccleston Square, London. SW1V 1PJ',
  '91 Tachbrook Street, London. SW1V 2QA',
  '11 MEADOW LN, OVER, CAMBRIDGE CB24 5NF',
]

expected_output = {
  "143 Castle Market, Sheffield. S1 2AF": {"confidence": 9, "street_number": None, "locality": "Central", "street_name": None, "longitude": "-1.46188317505", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "53.3844716984", "region": "Sheffield", "street_address": None}, 
  "3865 21st St, Boulder, CO 80304": {"confidence": 0.90200000000000002, "street_number": "3865", "locality": "Boulder", "street_name": "21st St", "longitude": -105.269209, "country_code3": "USA", "country_name": "United States", "fips_county": "08013", "country_code": "US", "latitude": 40.045673999999998, "region": "CO", "street_address": "3865 21st St"},
  "23 Churton Street, London. SW1V 2LY": {"confidence": 9, "street_number": "23", "locality": "Warwick", "street_name": "Churton Street", "longitude": "-0.1384815", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "51.4920369", "region": "Westminster", "street_address": "23 Churton Street"}, 
  "5 Anstey Way, Trumpington, Cambridge. CB2 9JE": {"confidence": 9, "street_number": "5", "locality": "Trumpington", "street_name": "Anstey Way", "longitude": "0.1151341", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "52.172827", "region": "Cambridge", "street_address": "5 Anstey Way"}, 
  "326 Abbeydale Road, Sheffield. S7 1FN": {"confidence": 9, "street_number": "326", "locality": "Nether Edge", "street_name": "Abbeydale Road", "longitude": "-1.47898487436395", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "53.3610919973962", "region": "Sheffield", "street_address": "326 Abbeydale Road"}, 
  "2543 Graystone Pl, Simi Valley, CA 93065": {"confidence": 0.92200000000000004, "street_number": "2543", "locality": "Simi Valley", "street_name": "Graystone Pl", "longitude": -118.76620699999999, "country_code3": "USA", "country_name": "United States", "fips_county": "06111", "country_code": "US", "latitude": 34.280873999999997, "region": "CA", "street_address": "2543 Graystone Pl"},
  "51 Warwick Way, London. SW1V 1QS": {"confidence": 9, "street_number": "51", "locality": "Warwick", "street_name": "Warwick Way", "longitude": "-0.139200838076716", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "51.4924172618438", "region": "Westminster", "street_address": "51 Warwick Way"}, 
  "23 Magdalene Street, Cambridge. CB3 0AF": {"confidence": 9, "street_number": "23", "locality": "Castle", "street_name": "Magdalene Street", "longitude": "0.116435", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "52.2098843", "region": "Cambridge", "street_address": "23 Magdalene Street"}, 
  "472 Glossop Road, Sheffield. S10 2QA": {"confidence": 9, "street_number": "472", "locality": "Broomhill", "street_name": "Glossop Road", "longitude": "-1.4989225314273", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "53.3764221287881", "region": "Sheffield", "street_address": "472 Glossop Road"}, 
  "309-311 Ecclesall Road, Sheffield. S11 8NX": {"confidence": 9, "street_number": "309", "locality": "Broomhill", "street_name": "Ecclesall Road", "longitude": "-1.48680040839211", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "53.3720267322457", "region": "Sheffield", "street_address": "309 Ecclesall Road"}, 
  "400 Duboce Ave #208, San Francisco, CA 94117": {"confidence": 0.92700000000000005, "street_number": "400", "locality": "San Francisco", "street_name": "Duboce Ave", "longitude": -122.42912800000001, "country_code3": "USA", "country_name": "United States", "fips_county": "06075", "country_code": "US", "latitude": 37.769455999999998, "region": "CA", "street_address": "400 Duboce Ave"},
  "72 Eccleston Square, London. SW1V 1PJ": {"confidence": 9, "street_number": None, "locality": "Warwick", "street_name": None, "longitude": "-0.141369261329", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "51.4915706843", "region": "Westminster", "street_address": None}, 
  "70 Rochester Rw, London. SW1P 1JU": {"confidence": 9, "street_number": "70", "locality": "Vincent Square", "street_name": "Rochester Row", "longitude": "-0.136287101294739", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "51.494735589944", "region": "Westminster", "street_address": "70 Rochester Row"}, 
  "3 The Broadway, Cambridge. CB1 3AH": {"confidence": 9, "street_number": "3", "locality": "Romsey", "street_name": "Broadway", "longitude": "0.0949181", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "52.1843634", "region": "Cambridge", "street_address": "3 Broadway"}, 
  "91 Tachbrook Street, London. SW1V 2QA": {"confidence": 9, "street_number": "91", "locality": "Tachbrook", "street_name": "Tachbrook Street", "longitude": "-0.1339006", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "51.4890442", "region": "Westminster", "street_address": "91 Tachbrook Street"}, 
  "26 Denbigh Street, London. SW1V 2ER": {"confidence": 9, "street_number": "26", "locality": "Warwick", "street_name": "Denbigh Street", "longitude": "-0.1393738765851", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "51.490634195143", "region": "Westminster", "street_address": "26 Denbigh Street"}, 
  "142 Castle Market, Sheffield. S1 2AF": {"confidence": 9, "street_number": None, "locality": "Central", "street_name": None, "longitude": "-1.46188317505", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "53.3844716984", "region": "Sheffield", "street_address": None}, 
  "35 Surrey Street, Sheffield. S1 2LG": {"confidence": 9, "street_number": "35", "locality": "Central", "street_name": "Surrey Street", "longitude": "-1.46765145016641", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "53.3801639620404", "region": "Sheffield", "street_address": "35 Surrey Street"}, 
  "5 Arbury Court, Cambridge. CB4 2JQ": {"confidence": 9, "street_number": None, "locality": "King's Hedges", "street_name": None, "longitude": "0.129886208578", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "52.2241815277", "region": "Cambridge", "street_address": None}, 
  "363 Sharrow Vale Road, Sheffield. S11 8ZG": {"confidence": 9, "street_number": "363", "locality": "Nether Edge", "street_name": "Sharrow Vale Road", "longitude": "-1.49839785957369", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "53.367555815374", "region": "Sheffield", "street_address": "363 Sharrow Vale Road"}, 
  "59 Ebury Street, London. SW1W 0NZ": {"confidence": 9, "street_number": "59", "locality": "Warwick", "street_name": "Ebury Street", "longitude": "-0.147190779445509", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "51.4959945275595", "region": "Westminster", "street_address": "59 Ebury Street"}, 
  "70 Division Street, Sheffield. S1 4GF": {"confidence": 9, "street_number": "70", "locality": "Central", "street_name": "Division Street", "longitude": "-1.47302453068155", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "53.3801969393084", "region": "Sheffield", "street_address": "70 Division Street"}, 
  "Addenbrookes Hosp, Hills Rd, Cambridge. CB2 2QQ": {"confidence": 8, "street_number": None, "locality": "Cambridge", "street_name": "Hills Road", "longitude": "0.1273966", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "52.199353", "region": None, "street_address": None}, 
  "Victoria Station, London. SW1V 1JY": {"confidence": 9, "street_number": None, "locality": "Warwick", "street_name": "Victoria Street", "longitude": "-0.143065416450093", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "51.4965774374698", "region": "Westminster", "street_address": None}, 
  "Hardwick Street, Cambridge. CB3 9JA": {"confidence": 9, "street_number": None, "locality": "Newnham", "street_name": "Hardwick Street", "longitude": "0.1088908", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "52.1950862", "region": "Cambridge", "street_address": None}, 
  "Victoria Station, London. SW1V 1JT": {"confidence": 9, "street_number": None, "locality": "Warwick", "street_name": "Victoria Street", "longitude": "-0.142632392027176", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "51.4965537502431", "region": "Westminster", "street_address": None}, 
  "6 Cathedral Walk Cardinal Place, London. SW1E 5JH": {"confidence": 9, "street_number": "6", "locality": "St James's", "street_name": "Cardinal Place", "longitude": "-0.2177927", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "51.4645664", "region": "Westminster", "street_address": "6 Cardinal Place"}, 
  "269 Fulwood Rd, S10. S10 3BD": {"confidence": 9, "street_number": "269", "locality": "Broomhill", "street_name": "Fulwood Road", "longitude": "-1.50146255148811", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "53.3773528827613", "region": "Sheffield", "street_address": "269 Fulwood Road"}, 
  "139-143 Milton Road, Cambridge. CB4 1XE": {"confidence": 9, "street_number": "139", "locality": "West Chesterton", "street_name": "Milton Road", "longitude": "0.133951984546466", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "52.220486593745", "region": "Cambridge", "street_address": "139 Milton Road"}, 
  "11 MEADOW LN, OVER, CAMBRIDGE CB24 5NF": {"confidence": 9, "street_number": "11", "locality": "Willingham and Over", "street_name": "Meadow Lane", "longitude": "0.0202307", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "52.3168159", "region": "South Cambridgeshire", "street_address": "11 Meadow Lane"},
  "261-263 Newmarket Road, Cambridge. CB5 8JE": {"confidence": 9, "street_number": "261", "locality": "Abbey", "street_name": "Newmarket Road", "longitude": "0.146200079031848", "country_code3": "GBR", "country_name": "United Kingdom", "fips_county": None, "country_code": "UK", "latitude": "52.2106264426397", "region": "Cambridge", "street_address": "261 Newmarket Road"}
}

actual_output = dstk.street2coordinates(test_input)

#print json.dumps(actual_output)

if len(expected_output) != len(actual_output):
  print json.dumps(actual_output)
  print('Expected '+str(len(expected_output))+' items, found '+str(len(actual_output)))
  exit(1)

for key, expected_values in expected_output.items():

  if key not in actual_output:
    print json.dumps(actual_output)
    print('Expected key "'+key+'" not found')
    exit(1)

  actual_values = actual_output[key]
  for value_index, expected_value in expected_values.items():
  
    if value_index not in actual_values:
      print json.dumps(actual_output)
      print('Expected value index "'+value_index+'" not found for "'+key+'"')
      exit(1)

    actual_value = actual_values[value_index]
    if actual_value != expected_value:
      print json.dumps(actual_output)
      print('Value "'+value_index+'":"'+key+'" was expected to be "'+str(expected_value)+'" but was actually "'+str(actual_value)+'"')
      exit(1)
    
print 'street2coordinates test passed'