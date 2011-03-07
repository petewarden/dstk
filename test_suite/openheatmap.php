#!/usr/bin/php
<?php
/******************************************************************************
 * An example of the way that the OpenHeatMap project uses the Yahoo          *
 * Placemaker API, to use as a testbed for Geodict's emulation of it          *
 ******************************************************************************/

// Original Yahoo API
//define('PLACEMAKER_URL', 'http://wherein.yahooapis.com/v1/document');
//define('YAHOO_PUBLIC_KEY', '');

// Local server
//define('PLACEMAKER_URL', 'http://localhost:4567/v1/document');
//define('YAHOO_PUBLIC_KEY', '');

// Remote server
define('PLACEMAKER_URL', 'http://geodictapi.com/v1/document');
define('YAHOO_PUBLIC_KEY', '');

define('PLACEMAKER_MAX_STRING_LENGTH', 4900);

function getPlaceMakerLocationsForList($locations_list) {
    global $g_last_error;
    
    $g_last_error = '';
    
    $result = array();
    $current_index = 0;
    $locations_count = count($locations_list);
    while ($current_index<$locations_count)
    {
        $item_offsets = array();
        $locations_string = '';
        while ($current_index<$locations_count)
        {
            $current_location = $locations_list[$current_index];

            $current_length = strlen($current_location);
            $existing_length = strlen($locations_string);
            $total_length = ($existing_length+$current_length);

            if ($total_length>=PLACEMAKER_MAX_STRING_LENGTH)
                break;
            
            for ($offset=$existing_length; $offset<$total_length; $offset+=1)
                $item_offsets[$offset] = $current_index;

            $locations_string .= $current_location."\n";
            
            $current_index += 1;
        }
        
        if (empty($locations_string))
        {
            $g_last_error = "An item that was too long to fit the Placemaker API limits was hit: $current_location";
            return null;
        }

        $response = callPlacemaker($locations_string);

        if (!$response)
            return null;
        
        $xml = simplexml_load_string($response);
        if ((!$xml)||
            (!$xml instanceof SimpleXMLElement)||
            (!isset($xml->document->placeDetails)))
        {
            $g_last_error = "Couldn't decode response as XML: '$response'";
            return null;
        }

        $woeid_map = array();
        foreach ($xml->document->referenceList->reference as $reference)
        {
            $start_offset = (int)($reference->start);
            if (!isset($item_offsets[$start_offset]))
            {
                continue;
            }
            
            $current_item = $item_offsets[$start_offset];
            
            $woeids_string = (string)($reference->woeIds);
            $woeids_list = explode(' ', $woeids_string);

            foreach ($woeids_list as $woeid)
            {
                $woeid_map[$woeid] = $current_item;
            }
        }

        $item_confidence = array();

        foreach ($xml->document->placeDetails as $place)
        {
            $confidence = (int)($place->confidence);
            $woeid = (string)($place->place->woeId);

            if (!isset($woeid_map[$woeid]))
                continue;

            $current_item = $woeid_map[$woeid];

//                error_log("Found ".print_r($place, true));

            if (isset($item_confidence[$current_item])&&
                ($item_confidence[$current_item]>$confidence))
                continue;
            
            $item_confidence[$current_item] = $confidence;                    
            
            $result[$current_item] = array(
                'lat' => (string)$place->place->centroid->latitude,
                'lon' => (string)$place->place->centroid->longitude,
            );
        }
    }
    
    return $result;
}
	
function callPlacemaker($locationName) {
    global $g_last_error;

    $ch = curl_init();

    $data = array(
        'documentContent'=>$locationName,
        'documentType'=>'text/plain',
        'outputType'=>'xml',
        'autoDisambiguate' => 'false', 
        'appid'=> YAHOO_PUBLIC_KEY);

    curl_setopt($ch, CURLOPT_URL, PLACEMAKER_URL);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT,30);
    curl_setopt($ch, CURLOPT_FAILONERROR, 1);
    curl_setopt($ch, CURLOPT_HEADER, 0);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $data);

    $output = curl_exec($ch);

    $response_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);

    if ($response_code!=200)
    {
        $g_last_error = 'Bad response code: ' . $response_code;
        $output = false;
    }
    else if(curl_errno($ch))
    {
        $g_last_error = 'Curl error: ' . curl_error($ch);
        $output = false;
    }
    curl_close($ch);
    return $output;
}

$text = file_get_contents('php://STDIN');
$list = explode("\n", $text);

$result = getPlaceMakerLocationsForList($list);

if (empty($result)) {
  die($g_last_error);
}

foreach ($result as $index => $info) {
    $location = $list[$index];
    
    print '"'.$location.'":{"lat":'.$info['lat'].',"lon":'.$info['lon'].'}'."\n";
}

?>
