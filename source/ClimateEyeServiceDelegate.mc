using Toybox.Background;
using Toybox.System;
using Toybox.Application as App;
using Toybox.Communications as Comm;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Greg;

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
                var callDate = "";     //calcHomeDateTime();
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
                        "msg"  => "CURRENTLY",
                        "callDate" => callDate
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
                        "msg"     => "DAILY",
                        "callDate" => callDate
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
     /// <summary>
    /// CLone of the calchomedatatime in order to see if I can harvest the current time that the last API call was done.  Not used currently as there are issues.
    /// </summary>
    /// <returns>array that contains Date and Time</returns>
    function calcHomeDateTime(){
        var dst  = App.getApp().getProperty("DST");
        var clockTime = System.getClockTime();
        var nowinfo = Greg.info(Time.now(), Time.FORMAT_SHORT);
        var dayOfWeek = nowinfo.day_of_week;
        var dayMonth = App.getApp().getProperty("DateFormat") == 0;
        var dateFormat = dayMonth ? "$1$.$2$" : "$2$/$1$";
        var monthAsText = App.getApp().getProperty("MonthAsText");
        var timezoneOffset = clockTime.timeZoneOffset;
        var showHomeTimezone = App.getApp().getProperty("ShowHomeTimezone");
        var showHomeDate = App.getApp().getProperty("ShowHomeDate");
        var homeTimezoneOffset = dst ? App.getApp().getProperty("HomeTimezoneOffset") + 3600 : App.getApp().getProperty("HomeTimezoneOffset");
        var onTravel = timezoneOffset != homeTimezoneOffset;

        var monthText = "";
        var timeText = "";
        var currentWeekdayText    = weekdays[dayOfWeek - 1];
        var currentDateText       = dayMonth ?  nowinfo.day.format(showLeadingZero ? "%02d" : "%01d") + " " + months[nowinfo.month - 1] : months[nowinfo.month - 1] + " " + nowinfo.day.format(showLeadingZero ? "%02d" : "%01d");
        var currentDateNumberText = Lang.format(dateFormat, [nowinfo.day.format(showLeadingZero ? "%02d" : "%01d"), nowinfo.month.format(showLeadingZero ? "%02d" : "%01d")]);
        monthText = currentWeekdayText + (monthAsText ? currentDateText : currentDateNumberText);
        
        if (!onTravel) {
            // if we are not traveling, just show the current date, time will be empty
            return [monthText, timeText];
        }

        if (showHomeTimezone || showHomeDate){
            // we are traveling. If we are showing either home Time or home Date, we need to calculate this
            var currentSeconds = clockTime.hour * 3600 + clockTime.min * 60 + clockTime.sec;
            var utcSeconds     = currentSeconds - clockTime.timeZoneOffset;
            var homeDayOfWeek  = dayOfWeek - 1;
            var homeDay        = nowinfo.day;
            var homeMonth      = nowinfo.month;
            var homeSeconds    = utcSeconds + homeTimezoneOffset;
            if (dst) { 
                homeSeconds = homeTimezoneOffset > 0 ? homeSeconds : homeSeconds - 3600; 
            }
            var homeHour       = ((homeSeconds / 3600)).toNumber() % 24l;
            var homeMinute     = ((homeSeconds - (homeHour.abs() * 3600)) / 60) % 60;
        
            if (homeHour < 0) {
                homeHour += 24;
                homeDay--;
                if (homeDay == 0) {
                    homeMonth--;
                    if (homeMonth == 0) { homeMonth = 12; }
                    homeDay = daysOfMonth(homeMonth);
                }
                homeDayOfWeek--;
                if (homeDayOfWeek < 0) { homeDayOfWeek = 6; }
            }
            if (homeMinute < 0) { homeMinute += 60; }

            var ampm = is24Hour ? "" : homeHour < 12 ? "A" : "P";
            homeHour = is24Hour ? homeHour : (homeHour == 12) ? homeHour : (homeHour % 12);
            
            if (showHomeDate) {
                // if we want to show the home date, we need to calculate it
                var homeWeekdayText    = weekdays[homeDayOfWeek];
                var homeDateText       = dayMonth ?  
                    homeDay.format(showLeadingZero ? "%02d" : "%01d") + " " + months[homeMonth - 1] : 
                      months[homeMonth - 1] + " " + homeDay.format(showLeadingZero ? "%02d" : "%01d");
                var homeDateNumberText = Lang.format(dateFormat, [homeDay.format(showLeadingZero ? "%02d" : "%01d"), homeMonth.format(showLeadingZero ? "%02d" : "%01d")]);
                monthText =  homeWeekdayText + (monthAsText ? homeDateText : homeDateNumberText);
            }

            timeText = Lang.format("$1$:$2$", [homeHour.format(showLeadingZero ? "%02d" : "%01d"), homeMinute.format("%02d")]) + ampm;
        }

        return [monthText, timeText];
    }
   
}