/*
 * jQuery Data Science Toolkit Plugin
 * version: 0.50 (2013-05-19)
 *
 * Example:
 *   var dstk = $.DSTK();
 *   dstk.street2coordinates('2543 Graystone Place, Simi Valley, CA 93065', myCallback);
 *
 * See http://www.datasciencetoolkit.org/developerdocs#javascript for a full
 * guide on how to use this interface.
 *
 * This jQuery plugin is a simple way to access the Data Science Toolkit
 * from Javascript. It's designed to work well cross-domain, using JSONP
 * calls. The only restriction is that the text-handling calls can't take
 * inputs of more than about 8k characters if going across domains, since
 * they're limited to the length of a URL. You can work around this either
 * by running your own copy of the server (it's available as a free VM and
 * Amazon EC2 image) or just using a proxy from your domain.
 * 
 * All code (C) Pete Warden, 2011
 *
 *    This program is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * 
 */
 
(function($) {

  // Call this to create a new Data Science Toolkit object, that you can then
  // use to make API calls.
  $.DSTK = function(options) {
  
    if ((typeof options == 'undefined')||(options == null)) {
      options = {};
    }  
  
    // These are the only dependencies on JQuery. If you want to run the code without
    // the framework, you can replace them with matching functions and call the
    // constructor directly, eg
    // var dstk = new DSTK({ajaxFunction: myAjax, toJSONFunction: myToJSON});
    options.ajaxFunction = $.ajax;
    options.toJSONFunction = $.toJSON;

    return new DSTK(options);
  };    
})(jQuery);

function DSTK(options) {
    
  var defaultOptions = {
    apiBase: 'http://www.datasciencetoolkit.org',
    checkVersion: true
  };
    
  if ((typeof options == 'undefined')||(options == null)) {
    options = defaultOptions;
  } else {
    for (var key in defaultOptions) {
      if (typeof options[key]=='undefined') {
        options[key] = defaultOptions[key];
      }
    }
  }
    
  this.apiBase = options.apiBase;
  this.ajaxFunction = options.ajaxFunction;
  this.toJSONFunction = options.toJSONFunction;
  
  if (options.checkVersion) {
    this.checkVersion();
  }
}

DSTK.prototype.checkVersion = function() {

  var requiredVersion = 50;

  var apiUrl = this.apiBase+'/info';
  
  this.ajaxFunction(apiUrl, {
    success: function(result) {
      var actualVersion = result['version'];
      if (actualVersion<requiredVersion) {
        throw 'DSTK: Version '+actualVersion+' found at "'+apiUrl+'" but '+requiredVersion+' is required';
      }
    },
    dataType: 'jsonp',
    crossDomain: true
  });

};

// See http://www.datasciencetoolkit.org/developerdocs for information on these calls

DSTK.prototype.ip2coordinates = function(ips, callback) {

  if (typeof ips.length == 'undefined') {
    ips = [ips];
  }

  var apiUrl = this.apiBase+'/ip2coordinates';
  apiUrl += '/'+encodeURIComponent($.toJSON(ips));

  this.ajaxFunction(apiUrl, {
    success: callback,
    dataType: 'jsonp',
    crossDomain: true
  });
};

DSTK.prototype.street2coordinates = function(addresses, callback) {

  if (typeof addresses.length == 'undefined') {
    addresses = [addresses];
  }

  var apiUrl = this.apiBase+'/street2coordinates';
  apiUrl += '/'+encodeURIComponent($.toJSON(addresses));

  $.ajax(apiUrl, {
    success: callback,
    dataType: 'jsonp',
    crossDomain: true
  });
};

DSTK.prototype.coordinates2politics = function(coordinates, callback) {

  if (typeof coordinates.length == 'undefined') {
    coordinates = [coordinates];
  }

  var apiUrl = this.apiBase+'/coordinates2politics';
  apiUrl += '/'+encodeURIComponent($.toJSON(coordinates));

  $.ajax(apiUrl, {
    success: callback,
    dataType: 'jsonp',
    crossDomain: true
  });
};

DSTK.prototype.text2places = function(text, callback) {
  this.makeTextCall(text, callback, 'text2places');
};

DSTK.prototype.text2sentences = function(text, callback) {
  this.makeTextCall(text, callback, 'text2sentences');
};

DSTK.prototype.html2text = function(html, callback) {
  this.makeTextCall(html, callback, 'html2text');
};

DSTK.prototype.html2story = function(html, callback) {
  this.makeTextCall(html, callback, 'html2story');
};

DSTK.prototype.text2people = function(text, callback) {
  this.makeTextCall(text, callback, 'text2people');
};

DSTK.prototype.text2times = function(text, callback) {
  this.makeTextCall(text, callback, 'text2times');
};

DSTK.prototype.googlestylegeocoder = function(address, callback) {
  var apiUrl = this.apiBase+'/maps/api/geocode/json';
  apiUrl += '?address='+encodeURIComponent(address);
  $.ajax(apiUrl, {
    success: callback,
    dataType: 'jsonp',
    crossDomain: true
  });
};

DSTK.prototype.text2sentiment = function(text, callback) {
  this.makeTextCall(text, callback, 'text2sentiment');
};

DSTK.prototype.coordinates2statistics = function(coordinates, callback) {

  if (typeof coordinates.length == 'undefined') {
    coordinates = [coordinates];
  }

  var apiUrl = this.apiBase+'/coordinates2statistics';
  apiUrl += '/'+encodeURIComponent($.toJSON(coordinates));

  $.ajax(apiUrl, {
    success: callback,
    dataType: 'jsonp',
    crossDomain: true
  });
};

DSTK.prototype.makeTextCall = function(text, callback, method) {

  var apiUrl = this.apiBase+'/'+method;
  var apiSuffix = encodeURIComponent($.toJSON([text]));

  if (apiSuffix.length<7500) {
    apiUrl += '/'+apiSuffix;

    $.ajax(apiUrl, {
      success: callback,
      dataType: 'jsonp',
      crossDomain: true
    });
  } else {

    $.ajax({
      url: apiUrl,
      data: text,
      success: callback,
      dataType: 'json',
      type: 'POST',
      crossDomain: true
    });
  
  }
};


/*
 * jQuery JSON Plugin
 * version: 2.1 (2009-08-14)
 *
 * This document is licensed as free software under the terms of the
 * MIT License: http://www.opensource.org/licenses/mit-license.php
 *
 * Brantley Harris wrote this plugin. It is based somewhat on the JSON.org 
 * website's http://www.json.org/json2.js, which proclaims:
 * "NO WARRANTY EXPRESSED OR IMPLIED. USE AT YOUR OWN RISK.", a sentiment that
 * I uphold.
 *
 * It is also influenced heavily by MochiKit's serializeJSON, which is 
 * copyrighted 2005 by Bob Ippolito.
 */
 
(function($) {
    /** jQuery.toJSON( json-serializble )
        Converts the given argument into a JSON respresentation.

        If an object has a "toJSON" function, that will be used to get the representation.
        Non-integer/string keys are skipped in the object, as are keys that point to a function.

        json-serializble:
            The *thing* to be converted.
     **/
    $.toJSON = function(o)
    {
        if (typeof(JSON) == 'object' && JSON.stringify)
            return JSON.stringify(o);
        
        var type = typeof(o);
    
        if (o === null)
            return "null";
    
        if (type == "undefined")
            return undefined;
        
        if (type == "number" || type == "boolean")
            return o + "";
    
        if (type == "string")
            return $.quoteString(o);
    
        if (type == 'object')
        {
            if (typeof o.toJSON == "function") 
                return $.toJSON( o.toJSON() );
            
            if (o.constructor === Date)
            {
                var month = o.getUTCMonth() + 1;
                if (month < 10) month = '0' + month;

                var day = o.getUTCDate();
                if (day < 10) day = '0' + day;

                var year = o.getUTCFullYear();
                
                var hours = o.getUTCHours();
                if (hours < 10) hours = '0' + hours;
                
                var minutes = o.getUTCMinutes();
                if (minutes < 10) minutes = '0' + minutes;
                
                var seconds = o.getUTCSeconds();
                if (seconds < 10) seconds = '0' + seconds;
                
                var milli = o.getUTCMilliseconds();
                if (milli < 100) milli = '0' + milli;
                if (milli < 10) milli = '0' + milli;

                return '"' + year + '-' + month + '-' + day + 'T' +
                             hours + ':' + minutes + ':' + seconds + 
                             '.' + milli + 'Z"'; 
            }

            if (o.constructor === Array) 
            {
                var ret = [];
                for (var i = 0; i < o.length; i++)
                    ret.push( $.toJSON(o[i]) || "null" );

                return "[" + ret.join(",") + "]";
            }
        
            var pairs = [];
            for (var k in o) {
                var name;
                var type = typeof k;

                if (type == "number")
                    name = '"' + k + '"';
                else if (type == "string")
                    name = $.quoteString(k);
                else
                    continue;  //skip non-string or number keys
            
                if (typeof o[k] == "function") 
                    continue;  //skip pairs where the value is a function.
            
                var val = $.toJSON(o[k]);
            
                pairs.push(name + ":" + val);
            }

            return "{" + pairs.join(", ") + "}";
        }
    };

    /** jQuery.evalJSON(src)
        Evaluates a given piece of json source.
     **/
    $.evalJSON = function(src)
    {
        if (typeof(JSON) == 'object' && JSON.parse)
            return JSON.parse(src);
        return eval("(" + src + ")");
    };
    
    /** jQuery.secureEvalJSON(src)
        Evals JSON in a way that is *more* secure.
    **/
    $.secureEvalJSON = function(src)
    {
        if (typeof(JSON) == 'object' && JSON.parse)
            return JSON.parse(src);
        
        var filtered = src;
        filtered = filtered.replace(/\\["\\\/bfnrtu]/g, '@');
        filtered = filtered.replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']');
        filtered = filtered.replace(/(?:^|:|,)(?:\s*\[)+/g, '');
        
        if (/^[\],:{}\s]*$/.test(filtered))
            return eval("(" + src + ")");
        else
            throw new SyntaxError("Error parsing JSON, source is not valid.");
    };

    /** jQuery.quoteString(string)
        Returns a string-repr of a string, escaping quotes intelligently.  
        Mostly a support function for toJSON.
    
        Examples:
            >>> jQuery.quoteString("apple")
            "apple"
        
            >>> jQuery.quoteString('"Where are we going?", she asked.')
            "\"Where are we going?\", she asked."
     **/
    $.quoteString = function(string)
    {
        if (string.match(_escapeable))
        {
            return '"' + string.replace(_escapeable, function (a) 
            {
                var c = _meta[a];
                if (typeof c === 'string') return c;
                c = a.charCodeAt();
                return '\\u00' + Math.floor(c / 16).toString(16) + (c % 16).toString(16);
            }) + '"';
        }
        return '"' + string + '"';
    };
    
    var _escapeable = /["\\\x00-\x1f\x7f-\x9f]/g;
    
    var _meta = {
        '\b': '\\b',
        '\t': '\\t',
        '\n': '\\n',
        '\f': '\\f',
        '\r': '\\r',
        '"' : '\\"',
        '\\': '\\\\'
    };
})(jQuery);
