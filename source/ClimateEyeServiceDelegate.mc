using Toybox.Background;
using Toybox.System;
using Toybox.Application as App;
using Toybox.Communications as Comm;

var uv;
var aqi;

(:background)
class ClimateEyeServiceDelegate extends System.ServiceDelegate {
    
    function initialize() {
        ServiceDelegate.initialize();        
    }
    
    function onTemporalEvent() {
    	var openWeather = false;
    	var apiKey = App.getApp().getProperty("OpenWeatherApiKey");
    	var uvApiKey = App.getApp().getProperty("OpenUVApiKey");
    	var aqiApiKey = App.getApp().getProperty("IQAirApiToken");
        
        var lat    = App.getApp().getProperty("UserLat").toFloat();
        var lng    = App.getApp().getProperty("UserLng").toFloat();
        var sunRise = App.getApp().getProperty("sunrise");
        var sunSet = App.getApp().getProperty("sunset");
        var UVStartHH = Math.floor(sunRise).toNumber();
        if (UVStartHH < 8) {UVStartHH=8;}
        var UVEndHH = Math.floor(sunSet).toNumber();
        if (UVEndHH > 18) {UVEndHH=18;}        
        
        if (System.getDeviceSettings().phoneConnected &&
            apiKey.length() > 0 &&
            (null != lat && null != lng)) {
            uv = null;
            aqi = null;
            var clockTime = System.getClockTime();
            // ok, gonna hardcode this in right now, but should probably do something better later.
            // doing this to get around the limit of 50 calls per day for UV
            if (clockTime.hour > UVStartHH and clockTime.hour < UVEndHH) {
                System.println("UV Request");
                //makeOpenWeatherUVRequest(lat, lng, apiKey);
                makeOpenUVRequest(lat, lng, uvApiKey);
            } else {
                System.println("aqi Request");
                makeAirVisualRequest(lat, lng, aqiApiKey);
                //makeOpenWeatherRequest(lat, lng, apiKey);
            }
        }
    }

    
    function makeOpenWeatherRequest(lat, lng, apiKey) {
        var currentWeather = App.getApp().getProperty("CurrentWeather");
        var url            = "https://api.openweathermap.org/data/2.5/weather?units=metric&lat=" + lat.toString() + "&lon=" + lng.toString() + "&appid=" + apiKey;
        System.println(url);
        var options = {
            :methods => Comm.HTTP_REQUEST_METHOD_GET,
            :headers => { "Content-Type" => Comm.REQUEST_CONTENT_TYPE_JSON },
            :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
                
        Comm.makeWebRequest(url, null, options, method(:onReceiveOpenWeather));
    }
    

    function onReceiveOpenWeather(responseCode, data) {
    System.println(data);
        if (responseCode == 200) {
            if (data instanceof Lang.String && data.equals("Forbidden")) {
                var dict = { "msg" => "KEY" };
                Background.exit(dict);
            } else {
                var currentWeather = App.getApp().getProperty("CurrentWeather");
                System.println("temp: " + data["main"]["temp"]);
                System.println("speed: " + data["wind"]["speed"]);
                System.println("gust: " + data["wind"]["gust"]);
                System.println("direction: " + data["wind"]["deg"]);
                System.println("uv: " + uv);
                System.println("aqi: " + aqi);
                if (currentWeather) {
                    var dict = {
                        "icon" => data["weather"][0]["icon"],
                        "temp" => data["main"]["temp"],
                        "wind" => data["wind"]["speed"],
                        "gust" => data["wind"]["gust"],
                        "direction" => data["wind"]["deg"],
                        "name" => data["name"],
                        "UV" => uv,
                        "aqi" => aqi,
                        "msg"  => "CURRENTLY"
                    };
                  Background.exit(dict);

                } else {
                    var dict = {
                        "icon" => data["weather"][0]["icon"],
                        "minTemp" => data["main"]["temp_min"],
                        "maxTemp" => data["main"]["temp_max"],
                        "wind" => data["wind"]["speed"],
                        "gust" => data["wind"]["gust"],
                        "direction" => data["wind"]["deg"],
                        "name" => data["name"],
                        "UV" => uv,
                        "AQI" => aqi,
                        "msg"     => "DAILY"
                    };
                    Background.exit(dict);
                }
            }
        } else {
            var dict = { "msg" => responseCode + " FAIL" };
            Background.exit(dict);
        }
    }
    
    function makeOpenUVRequest(lat, lng, apiKey) {
        var url            = "https://api.openuv.io/api/v1/uv?lat=" + lat.toString() + "&lng=" + lng.toString();
        System.println(url);
        var options = {
            :methods => Comm.HTTP_REQUEST_METHOD_GET,
            :headers => { "Content-Type" => Comm.REQUEST_CONTENT_TYPE_JSON, 
                           "x-access-token"=> "4faec78c46a3f9361e2c48c844794b18"
                       },
            :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
                
        Comm.makeWebRequest(url, null, options, method(:onReceiveOpenUV));
    }
    
    function onReceiveOpenUV(responseCode, data) {
    System.println(data);
        if (responseCode == 200) {
            if (data instanceof Lang.String && data.equals("Forbidden")) {
            } else {
                var result = data.get("result");
                uv = result.get("uv");
                System.println("uv: " + uv);
            }
        }
        // have to make sure we don't exit the background in failure - need to still get the weather.
    	var apiKey = App.getApp().getProperty("IQAirApiToken");
        var lat    = App.getApp().getProperty("UserLat").toFloat();
        var lng    = App.getApp().getProperty("UserLng").toFloat();
        makeAirVisualRequest(lat, lng, apiKey);
    }
    

    function makeAirVisualRequest(lat, lng, apiKey) {
        var url = "https://api.airvisual.com/v2/nearest_city?key=" + apiKey + "&lat=" + lat.toString() + "&lon=" + lng.toString();
        System.println(url);
        var options = {
            :methods => Comm.HTTP_REQUEST_METHOD_GET,
            :headers => { "Content-Type" => Comm.REQUEST_CONTENT_TYPE_JSON },
            :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
                
        Comm.makeWebRequest(url, null, options, method(:onReceiveAirVisual));
    }

    function onReceiveAirVisual(responseCode, data) {
    System.println(responseCode);
    System.println(data);
        if (responseCode == 200) {
            var result = data["data"];
            println(result);
            aqi = result["current"]["pollution"]["aqius"];
            System.println("aqi: " + aqi);
        }
        // have to make sure we don't exit the background in failure - need to still get the weather.
    	var apiKey = App.getApp().getProperty("OpenWeatherApiKey");
        var lat    = App.getApp().getProperty("UserLat").toFloat();
        var lng    = App.getApp().getProperty("UserLng").toFloat();
        makeOpenWeatherRequest(lat, lng, apiKey);
        //Background.exit(dict);
    }
    
}