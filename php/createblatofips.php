#!/usr/bin/php
<?php

/*
OpenGraphMap processing
Copyright (C) 2010 Pete Warden <pete@petewarden.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

require_once('cliargs.php');

function load_fips_definitions($file_name)
{
    $file_handle = fopen($file_name, "r") or die("Couldn't open $file_name\n");

    $result = array();

    $line_index = 0;
    while(!feof($file_handle))
    {
        $current_line = fgets($file_handle);
        $line_index += 1;
        if ($line_index<12)
            continue;

        $code_0 = substr($current_line, 0, 4);
        $code_1 = substr($current_line, 8, 4);
        $fips_code = substr($current_line, 16, 5);
        $area_type = substr($current_line, 25, 1);
        $description = substr($current_line, 30);
        
        if ($area_type==='1')
            continue;
        
        $description = trim($description);
        $description = strtolower($description);
        $result[$description] = array(
            'fips_code' => $fips_code,
        );
    }
    
    fclose($file_handle);
    
    return $result;
}

function load_90s_fips_definitions($file_name, $do_normalize=false)
{
    $state_postal_codes = array(
        '01' => 'AL',
        '29' => 'MO',
        '02' => 'AK',
        '30' => 'MT',
        '04' => 'AZ',
        '31' => 'NE',
        '05' => 'AR',
        '32' => 'NV',
        '06' => 'CA',
        '33' => 'NH',
        '08' => 'CO',
        '34' => 'NJ',
        '09' => 'CT',
        '35' => 'NM',
        '10' => 'DE',
        '36' => 'NY',
        '11' => 'DC',
        '37' => 'NC',
        '12' => 'FL',
        '38' => 'ND',
        '13' => 'GA',
        '39' => 'OH',
        '40' => 'OK',
        '41' => 'OR',
        '15' => 'HI',
        '42' => 'PA',
        '16' => 'ID',
        '44' => 'RI',
        '17' => 'IL',
        '45' => 'SC',
        '18' => 'IN',
        '46' => 'SD',
        '19' => 'IA',
        '47' => 'TN',
        '20' => 'KS',
        '48' => 'TX',
        '21' => 'KY',
        '49' => 'UT',
        '22' => 'LA',
        '50' => 'VT',
        '23' => 'ME',
        '51' => 'VA',
        '24' => 'MD',
        '53' => 'WA',
        '25' => 'MA',
        '54' => 'WV',
        '26' => 'MI',
        '55' => 'WI',
        '27' => 'MN',
        '56' => 'WY',
        '28' => 'MS',
        '60' => 'AS',
        '64' => 'FM',
        '66' => 'GU',
        '68' => 'MH',
        '69' => 'MP',
        '70' => 'PW',
        '72' => 'PR',
        '74' => 'UM',
        '78' => 'VI',
    );

    $file_handle = fopen($file_name, "r") or die("Couldn't open $file_name\n");

    $result = array();

    $line_index = 0;
    while(!feof($file_handle))
    {
        $current_line = fgets($file_handle);
        $line_index += 1;
        if ($line_index<97)
            continue;

        if (empty($current_line))
            continue;

        $fips_code = substr($current_line, 4, 5);
        $description = substr($current_line, 17);
        
        $state_code = substr($fips_code, 0, 2);
        $county_code = substr($fips_code, 2, 3);
        
        if ($county_code==='000')
            continue;

        if (!isset($state_postal_codes[$state_code]))
            die("Postal code not found for '$state_code'");

        $description = trim($description);

        $postal_code = $state_postal_codes[$state_code];
        $description .= ', '.$postal_code;

        if ($do_normalize)
        {
            $description = strtolower($description);
            
            $description = str_replace(' county,', ',', $description);
            $description = str_replace(' city,', ',', $description);
        }
        
        if (!isset($result[$description]) ||
            ($result[$description]['fips_code']>$fips_code))
            $result[$description] = array(
                'fips_code' => $fips_code,
            );
    }
    
    fclose($file_handle);
    
    return $result;
}

function match_bla_to_fips($input_file_name, $output_file_name, $fips_definitions)
{
    $input_file_handle = fopen($input_file_name, "r") or die("Couldn't open $input_file_name\n");
    $output_file_handle = fopen($output_file_name, "w") or die("Couldn't open $output_file_name\n");

    $fixups = array(
        'laporte, in' => 'la porte, in',
        'lasalle, il' => 'la salle, il',
//        'dekalb, al' => 'de kalb, al',
//        'dewitt, tx' => 'de witt, tx',
//        'lamoure, nd' => 'la moure, nd',
//        'dekalb, mo' => 'de kalb, mo',
        'dekalb, in' => 'de kalb, in',
//        'dekalb, ga' => 'de kalb, ga',
//        'miami-dade, fl' => 'dade, fl',
//        'desoto, fl' => 'de soto, fl',
        'de baca, nm' => 'debaca, nm',
        'mckean, pa' => 'mc kean, pa',
    );

    fwrite($output_file_handle, '"bla_code","fips_code","series_code","description"'."\n");

    $line_index = 0;
    while(!feof($input_file_handle))
    {
        $current_line = fgets($input_file_handle);

        $line_index += 1;
        if ($line_index<2)
            continue;

        $input_parts = explode("\t", $current_line);
        
        if (count($input_parts)<3)
            continue;
      
        // Only look at counties or county-equivalents
        $area_type_code = strip($input_parts[0]);
        if ($area_type_code !== 'F') {
          continue;
        }

        $area_code = $input_parts[1];
        $series_code = substr($area_code, 0, 2);
        $bla_code = substr($area_code, 2, 6);
        
        $area_text = $input_parts[2];
        $area_text = trim($area_text);
        $area_text = strtolower($area_text);
        $normalized_county = str_replace(' county/city', '', $area_text);
        $normalized_county = str_replace(' city', '', $normalized_county);
        $normalized_county = str_replace(' county/town', '', $normalized_county);
        $normalized_county = str_replace(' county', '', $normalized_county);

        if (isset($fixups[$normalized_county]))
            $normalized_county = $fixups[$normalized_county];

        if (isset($fips_definitions[$normalized_county]))
        {
            $fips_code = $fips_definitions[$normalized_county]['fips_code'];
        
            $output_parts = array(
                $bla_code,
                $fips_code,
                $series_code,
                $normalized_county,
            );
            
            fputcsv($output_file_handle, $output_parts);        
        }
        else
        {
            if ($area_text!==$normalized_county)
            {
                if (!strpos($area_text, 'county part')&&
                    !strpos($area_text, 'statistical area')&&
                    !strpos($area_text, 'township')&&
                    !strpos($area_text, 'town')&&
                    !strpos($area_text, 'city')&&
                    !strpos($area_text, 'metropolitan'))
                    die("It looks like a county, but no FIPS found for $area_text ($normalized_county)");
            }
        }
        
    }
    
    fclose($input_file_handle);
    fclose($output_file_handle);
}

function output_fips_translation_table($output_file_name, $fips_definitions)
{
    $output_file_handle = fopen($output_file_name, "w") or die("Couldn't open $output_file_name\n");

    foreach ($fips_definitions as $description => $info)
    {
        $fips_code = $info['fips_code'];
        $state_code = substr($fips_code, 0, 2);
        $county_code = substr($fips_code, 2, 3);
        
        fwrite($output_file_handle, "'$description' => array('$state_code', '$county_code'),\n");
    }

    fclose($output_file_handle);
}

function output_fips_accepted_values($output_file_name, $fips_definitions)
{
    $output_file_handle = fopen($output_file_name, "w") or die("Couldn't open $output_file_name\n");

    foreach ($fips_definitions as $description => $info)
    {
        $fips_code = $info['fips_code'];

        $county_code = substr($fips_code, 2, 3);
        
        fwrite($output_file_handle, "'$county_code',\n");
    }

    fclose($output_file_handle);
}

$cliargs = array(
	'fipsfile' => array(
		'short' => 'f',
		'type' => 'required',
		'description' => 'The location of the file listing the FIPS county definitions',
	),
	'blafile' => array(
		'short' => 'b',
		'type' => 'optional',
		'description' => 'The location of the BLA area definitions file',
        'default' => '',
	),
	'outputfile' => array(
		'short' => 'o',
		'type' => 'optional',
		'description' => 'The file to write the output csv data to - if unset, will write to stdout',
        'default' => 'php://stdout',
	),
    'action' => array(
        'short' => 'a',
        'type' => 'optional',
        'description' => 'What operation to perform on the FIPS data, eg match, translate, accept',
        'default' => 'match',
    ),
);	

$options = cliargs_get_options($cliargs);

$fips_file = $options['fipsfile'];
$bla_file = $options['blafile'];
$output_file = $options['outputfile'];
$action = $options['action'];

$do_normalize = ($action==='match');

$fips_definitions = load_90s_fips_definitions($fips_file, $do_normalize);

switch ($action)
{
    case 'match':
        if (empty($bla_file))
        {
            print "You must specify a BLA file for the match action\n";
            cliargs_print_help_and_exit($cliargs);        
        }
        match_bla_to_fips($bla_file, $output_file, $fips_definitions);
    break;
    
    case 'translate':
        output_fips_translation_table($output_file, $fips_definitions);
    break;
    
    case 'accept':
        output_fips_accepted_values($output_file, $fips_definitions);
    break;

    default:
        print "Unknown action '$action'\n";
        cliargs_print_help_and_exit($cliargs);
    break;
}
    
?>