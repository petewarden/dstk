#!/usr/bin/env python

# An example of the way that a Python project uses the Yahoo
# Placemaker API, to use as a testbed for Geodict's emulation of it

import urllib
from xml.dom import minidom
import re
import sys
import inspect

# Original Yahoo API
#__YH_URL = "http://wherein.yahooapis.com/v1/document"
#__YH_APP_ID = ""

# Local server
__YH_URL = 'http://localhost:4567/v1/document'
__YH_APP_ID = ''

# Remote server
#__YH_URL = 'http://geodictapi.com/v1/document'
#__YH_APP_ID = ''

class YHPlaceType(object):
    CONTINENT   = 29
    COUNTRY     = 12
    ADMIN       =  8
    ADMIN2      =  9
    ADMIN3      = 10
    TOWN        =  7
    SUBURB      = 22
    POSTAL_CODE = 11
    SUPERNAME   = 19
    COLLOQUIAL  = 24
    TIME_ZONE   = 31

    @staticmethod
    def get_from_str(type):
        type = type.strip()
        type = re.sub(r'\s+', '_', type)
        type = type.upper()
        if hasattr(YHPlaceType, type):
            return getattr(YHPlaceType, type)
        return None

class YHPlace(object):
    def __init__(self):
        self.name  = ""
        self.lat   = -1
        self.lng   = -1
        self.woeid = -1

        self._type  = None

    def gettype(self): return self._type

    def settype(self, type):
        self._type = YHPlaceType.get_from_str(type)

    type = property(gettype, settype)

class YHPlaceDetails(object):
    def __init__(self):
        self.weight     = -1
        self.confidence = -1
        self.place      = None

class YHDocument(object):
    def __init__(self):
        self.admin_scope  = None
        self.geo_scope    = None
        self.extents      = {"center"   : (-1, -1),
                             "southwest": (-1, -1),
                             "northeast": (-1, -1)}
        self.placedetails = []

def locationsFromText(text):
    def read_text(xml_elem):
        return xml_elem.firstChild.wholeText

    def parse_place(place):

        res = YHPlace()
        res.woeid = int(read_text(place.getElementsByTagName("woeId")[0]))
        res.name  = read_text(place.getElementsByTagName("name")[0])
        res.type  = read_text(place.getElementsByTagName("type")[0])

        centroid = place.getElementsByTagName("centroid")[0]
        res.lat   = \
            float(read_text(centroid.getElementsByTagName("latitude" )[0]))
        res.lng   = \
            float(read_text(centroid.getElementsByTagName("longitude")[0]))

        return res

    def parse_place_detail(place_detail):

        res = YHPlaceDetails()
        res.weight = \
            int(read_text(place_detail.getElementsByTagName("weight")[0]))
        res.confidence = \
            int(read_text(place_detail.getElementsByTagName("confidence")[0]))
        res.place = parse_place(place_detail.getElementsByTagName("place")[0])
        return res
    params = {
        "documentContent": text
      , "documentType"   : "text/plain"
      , "appid"          : __YH_APP_ID
    }
    params_str = urllib.urlencode(params)
    response = urllib.urlopen(__YH_URL, data=params_str)
    dom = minidom.parse(response)
    doc = dom.getElementsByTagName("document")[0]

    has_child_elems = False
    for cn in doc.childNodes:
        if cn.nodeType == cn.ELEMENT_NODE:
            has_child_elems = True
            break
    if not has_child_elems: return None

    res = YHDocument()

    res.geo_scope = parse_place(doc.getElementsByTagName("geographicScope")[0])

    extents = doc.getElementsByTagName("extents")[0]

    center = extents.getElementsByTagName("center")[0]
    res.extents["center"] = (
        float(read_text(center.getElementsByTagName("latitude" )[0]))
      , float(read_text(center.getElementsByTagName("longitude")[0]))
    )
    southwest = extents.getElementsByTagName("southWest")[0]
    res.extents["southwest"] = (
        float(read_text(southwest.getElementsByTagName("latitude" )[0]))
      , float(read_text(southwest.getElementsByTagName("longitude")[0]))
    )
    northeast = extents.getElementsByTagName("northEast")[0]
    res.extents["northeast"] = (
        float(read_text(northeast.getElementsByTagName("latitude" )[0]))
      , float(read_text(northeast.getElementsByTagName("longitude")[0]))
    )

    for pd in doc.getElementsByTagName("placeDetails"):
        res.placedetails.append(parse_place_detail(pd))

    dom.unlink()
    return res

text = sys.stdin.read()

result = locationsFromText(text)

for pd in result.placedetails:
  print vars(pd.place)