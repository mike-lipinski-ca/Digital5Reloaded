using Toybox.Background;
using Toybox.System;
using Toybox.Application as App;
using Toybox.Communications as Comm;

var uv;

(:background)
class ClimateEyeServiceDelegate extends System.ServiceDelegate {
    
    function initialize() {
        ServiceDelegate.initialize();        
    }
    
    function onTemporalEvent() {
    	var openWeather = false;
    	var apiKey = App.getApp().getProperty("OpenWeatherApiKey");
    	var uvApiKey = App.getApp().getProperty("OpenUVApiKey");
    	if (apiKey.length() > 0) {
    		openWeather = true;
    	} else {
    	  apiKey = App.getApp().getProperty("DarkSkyApiKey");
    	}
        
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
            if (openWeather){
                uv = null;
                var clockTime = System.getClockTime();
                // ok, gonna hardcode this in right now, but should probably do something better later.
                // doing this to get around the limit of 50 calls per day for UV
                if (clockTime.hour > UVStartHH and clockTime.hour < UVEndHH) {
                  System.println("UV Request");
                  //makeOpenWeatherUVRequest(lat, lng, apiKey);
                  makeOpenUVRequest(lat, lng, uvApiKey);
                } else {
                  System.println("weather Request");
                  makeOpenWeatherRequest(lat, lng, apiKey);
                }
            } else {
                makeDarkSkyRequest(lat, lng, apiKey);
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
    
    function makeOpenWeatherUVRequest(lat, lng, apiKey) {
        var currentWeather = App.getApp().getProperty("CurrentWeather");
        var url            = "https://api.openweathermap.org/data/2.5/uvi?lat=" + lat.toString() + "&lon=" + lng.toString() + "&appid=" + apiKey;
        System.println(url);
        var options = {
            :methods => Comm.HTTP_REQUEST_METHOD_GET,
            :headers => { "Content-Type" => Comm.REQUEST_CONTENT_TYPE_JSON },
            :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
                
        Comm.makeWebRequest(url, null, options, method(:onReceiveOpenWeatherUV));
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
    function onReceiveOpenWeather(responseCode, data) {
    System.println(data);
        if (responseCode == 200) {
            if (data instanceof Lang.String && data.equals("Forbidden")) {
                var dict = { "msg" => "KEY" };
                Background.exit(dict);
            } else {
                var currentWeather = App.getApp().getProperty("CurrentWeather");
                //var main = data.get("main");
                //var weather = data.get("weather")[0];
                //var wind = data.get("wind");
                System.println("temp: " + data["main"]["temp"]);
                System.println("speed: " + data["wind"]["speed"]);
                System.println("gust: " + data["wind"]["gust"]);
                System.println("direction: " + data["wind"]["deg"]);
                System.println("uv: " + uv);
                if (currentWeather) {
                    var dict = {
                        "icon" => data["weather"][0]["icon"],
                        "temp" => data["main"]["temp"],
                        "wind" => data["wind"]["speed"],
                        "gust" => data["wind"]["gust"],
                        "direction" => data["wind"]["deg"],
                        "name" => data["name"],
                        "UV" => uv,
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
    
    function onReceiveOpenWeatherUV(responseCode, data) {
    System.println(data);
        if (responseCode == 200) {
            if (data instanceof Lang.String && data.equals("Forbidden")) {
                var dict = { "msg" => "UVKEY" };
                //Background.exit("KEY");
            } else {
                var currentWeather = App.getApp().getProperty("CurrentWeather");
                uv = data.get("value");
                System.println("uv: " + uv);
                var dict = { "UV" => uv,
                   "msg" => "UV"
                   };
            }
        } else {
            var dict = { "msg" => responseCode + " UVFAIL" };
            //Background.exit("FAIL");
        }
        // have to make sure we don't exit the background in failure - need to still get the weather.
    	var apiKey = App.getApp().getProperty("OpenWeatherApiKey");
        var lat    = App.getApp().getProperty("UserLat").toFloat();
        var lng    = App.getApp().getProperty("UserLng").toFloat();
        makeOpenWeatherRequest(lat, lng, apiKey);
        //Background.exit(dict);
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
    	var apiKey = App.getApp().getProperty("OpenWeatherApiKey");
        var lat    = App.getApp().getProperty("UserLat").toFloat();
        var lng    = App.getApp().getProperty("UserLng").toFloat();
        makeOpenWeatherRequest(lat, lng, apiKey);
        //Background.exit(dict);
    }
    


    function makeDarkSkyRequest(lat, lng, apiKey) {
        var currentWeather = App.getApp().getProperty("CurrentWeather");
        var url            = "https://api.darksky.net/forecast/" + apiKey + "/" + lat.toString() + "," + lng.toString();
        var params;
        if (currentWeather) {
            params = { "exclude" => "daily,minutely,hourly,alerts,flags", "units" => "si" };
        } else {
            url    = url + "," + Time.now().value();
            params = { "exclude" => "currently,minutely,hourly,alerts,flags", "units" => "si" };
        }
        var options = {
            :methods => Comm.HTTP_REQUEST_METHOD_GET,
            :headers => { "Content-Type" => Comm.REQUEST_CONTENT_TYPE_JSON },
            :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        
        if ($.debug) {System.println("ClimateEyeServiceDelegate.makeRequest - url: " + url + ", params: " + params);}
        
        Comm.makeWebRequest(url, params, options, method(:onReceiveDarkSky));
    }
    
    function onReceiveDarkSky(responseCode, data) {
        if (responseCode == 200) {
            if (data instanceof Lang.String && data.equals("Forbidden")) {
                var dict = { "msg" => "KEY" };
                Background.exit(dict);
            } else {
                var currentWeather = App.getApp().getProperty("CurrentWeather");
                if (currentWeather) {
                    var currently = data.get("currently");
                    var dict = {
                        "icon" => currently.get("icon"),
                        "temp" => currently.get("temperature"),
                        "msg"  => "CURRENTLY"
                    };
                    Background.exit(dict);
                } else {
                    var daily = data.get("daily");
                    var days  = daily.get("data");
                    var today = days[0];
                    var dict = {
                        "icon"    => today.get("icon"),
                        "minTemp" => today.get("temperatureMin"),
                        "maxTemp" => today.get("temperatureMax"),
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
}