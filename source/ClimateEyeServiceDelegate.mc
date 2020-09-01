using Toybox.Background;
using Toybox.System;
using Toybox.Application as App;
using Toybox.Communications as Comm;

(:background)
class ClimateEyeServiceDelegate extends System.ServiceDelegate {
    
    function initialize() {
        ServiceDelegate.initialize();        
    }
    
    function onTemporalEvent() {
    	var openWeather = false;
    	var apiKey = App.getApp().getProperty("OpenWeatherApiKey");
    	if (apiKey.length() > 0) {
    		openWeather = true;
    	} else {
    	  apiKey = App.getApp().getProperty("DarkSkyApiKey");
    	}
        
        var lat    = App.getApp().getProperty("UserLat").toFloat();
        var lng    = App.getApp().getProperty("UserLng").toFloat();
        
        if (System.getDeviceSettings().phoneConnected &&
            apiKey.length() > 0 &&
            (null != lat && null != lng)) {
            if (openWeather){
                makeOpenWeatherRequest(lat, lng, apiKey);
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
        var url            = "https://api.openweathermap.org/data/2.5/uvi/forecast?lat=" + lat.toString() + "&lon=" + lng.toString() + "&appid=" + apiKey;
        System.println(url);
        var options = {
            :methods => Comm.HTTP_REQUEST_METHOD_GET,
            :headers => { "Content-Type" => Comm.REQUEST_CONTENT_TYPE_JSON },
            :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
                
        Comm.makeWebRequest(url, null, options, method(:onReceiveOpenWeatherUV));
    }

    function onReceiveOpenWeather(responseCode, data) {
    System.println(data);
        if (responseCode == 200) {
            if (data instanceof Lang.String && data.equals("Forbidden")) {
                var dict = { "msg" => "KEY" };
                Background.exit(dict);
            } else {
                var currentWeather = App.getApp().getProperty("CurrentWeather");
                var main = data.get("main");
                var weather = data.get("weather")[0];
                var wind = data.get("wind");
                System.println("temp: " + main.get("temp"));
                System.println("speed: " + wind.get("speed"));
                System.println("gust: " + wind.get("gust"));
                System.println("direction: " + wind.get("deg"));
                if (currentWeather) {
                    var dict = {
                        "icon" => weather.get("icon"),
                        "temp" => main.get("temp"),
                        "wind" => wind.get("speed"),
                        "gust" => wind.get("gust"),
                        "direction" => wind.get("deg"),
                        "msg"  => "CURRENTLY"
                    };
                    Background.exit(dict);
                } else {
                    var dict = {
                        "icon"    => weather.get("icon"),
                        "minTemp" => main.get("temp_min"),
                        "maxTemp" => main.get("temp_max"),
                        "wind" => wind.get("speed"),
                        "gust" => wind.get("gust"),
                        "direction" => wind.get("deg"),
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
                var dict = { "msg" => "KEY" };
                Background.exit("KEY");
            } else {
                var currentWeather = App.getApp().getProperty("CurrentWeather");
                var uv = data.get("value");
                background.exit(data.get("value"));
            }
        } else {
            var dict = { "msg" => responseCode + " FAIL" };
            Background.exit("FAIL");
        }
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