#!/usr/bin/php
<?php

/******************************************************************************
 * An example of the way that the Ushahidi/Swift project uses the Yahoo       *
 * Placemaker API, to use as a testbed for Geodict's emulation of it          *
 ******************************************************************************/

// Original Yahoo API
//define('BASE_URL', 'http://wherein.yahooapis.com/');
//define('APP_ID', '');

// Local server
define('BASE_URL', 'http://localhost:4567/');
define('APP_ID', '');

// Remote server
//define('BASE_URL', 'http://www.geodictapi.com/');
//define('APP_ID', '');

function curl_request($url, $postvars = null)
{
    $ch = curl_init();
    $timeout = 10; // set to zero for no timeout
    curl_setopt ($ch, CURLOPT_URL, $url);
    curl_setopt ($ch, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt ($ch, CURLOPT_CONNECTTIMEOUT, $timeout);

    if($postvars != null)
    {
        curl_setopt($ch, CURLOPT_POST, 1);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $postvars);
    }

    $file_contents = curl_exec($ch);
    curl_close($ch);
    return $file_contents;
}

function YahooPlacemakerRequest($location, $appid)
{
    $encodedLocation = \urlencode($location);
    $url = BASE_URL."v1/document";
    $postvars = "documentContent=$encodedLocation&documentType=text/plain&appid=$appid";
    $return = curl_request($url, $postvars);
    $xml = new \SimpleXMLElement($return);
    $long = (float) $xml->document->placeDetails->place->centroid->longitude;
    $latt = (float) $xml->document->placeDetails->place->centroid->latitude;
    $gis = array('lon' => $long, 'lat' => $latt, 'location' => $location);
    return $gis;
}

$text = file_get_contents('php://STDIN');

$result = YahooPlacemakerRequest($text, APP_ID);

print_r($result);

?>
