using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Background;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;

(:background)
class ClimateEyeApp extends App.AppBase {
    hidden var view;
    hidden var sunRiseSet;


    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {}
    function onStop(state) {}

    function getInitialView() {
        if (null == App.getApp().getProperty("ActKcalAvg")) {
            var actKcalAvg = [0, 0, 0, 0, 0, 0];
            App.getApp().setProperty("ActKcalAvg", actKcalAvg);
        }
        
        sunRiseSet = new SunRiseSunSet();

        view = new ClimateEyeView();
        
        Background.registerForTemporalEvent(new Time.Duration(900)); // 15 min
        
        if( Toybox.WatchUi has :WatchFaceDelegate ) {
            return [view, new ClimateEyeDelegate()];
        } else {
            return [view];
        }
    }
    
    function getServiceDelegate() {
        return [new ClimateEyeServiceDelegate()]; 
    }

    function onBackgroundData(data) {
      //System.println("onBAckgrounddata");
    	var openWeather = false;
    	var apiKey = App.getApp().getProperty("OpenWeatherApiKey");
    	if (apiKey.length() > 0) {
    		openWeather = true;
    	} else {
    	  apiKey = App.getApp().getProperty("DarkSkyApiKey");
    	}
    	    
      System.println("Data: " + data);
      if (data instanceof Dictionary) {
          var msg = data.get("msg");
          System.println("msg " + msg);
          App.getApp().setProperty("dsResult", msg);
          if (msg.equals("CURRENTLY")) {
              App.getApp().setProperty("temp", data.get("temp"));
              App.getApp().setProperty("UV", data.get("UV"));
              App.getApp().setProperty("aqi", data.get("aqi"));
          } else if (msg.equals("DAILY")) {
              App.getApp().setProperty("minTemp", data.get("minTemp"));
              App.getApp().setProperty("maxTemp", data.get("maxTemp"));
          }
          // rain, snow, sleet, wind, fog, cloudy
          // https://openweathermap.org/weather-conditions#How-to-get-icon-URL

          if (msg.equals("CURRENTLY") or msg.equals("DAILY")) {

            App.getApp().setProperty("wind", data.get("wind"));
            var gust = data.get("gust");
            if (gust == null) {
                //gust = data.get("wind");
            }
            App.getApp().setProperty("gust", gust);
            App.getApp().setProperty("City", data.get("name"));

            var degrees = data.get("direction");
                        System.println("degrees " + degrees);
            var deg;
            var direction = "-";
            if (openWeather){
              if (degrees != null){
                degrees = Toybox.Math.round(degrees/22.5).toLong()+1;
                deg = degrees;
                        System.println("mod " + deg);
                if (deg == 1) {
                  App.getApp().setProperty("direction", "N");
                } else if (deg == 2){
                  App.getApp().setProperty("direction", "NNE");
                } else if (deg == 3){
                  App.getApp().setProperty("direction", "NE");
                } else if (deg == 4){
                  App.getApp().setProperty("direction", "ENE");
                } else if (deg == 5){
                  App.getApp().setProperty("direction", "E");
                } else if (deg == 6){
                  App.getApp().setProperty("direction", "ESE");
                } else if (deg == 7){
                  App.getApp().setProperty("direction", "SE");
                } else if (deg == 8){
                  App.getApp().setProperty("direction", "SSE");
                } else if (deg == 9){
                  App.getApp().setProperty("direction", "S");
                } else if (deg == 10){
                  App.getApp().setProperty("direction", "SSW");
                } else if (deg == 11){
                  App.getApp().setProperty("direction", "SW");
                } else if (deg == 12){
                  App.getApp().setProperty("direction", "WSW");
                } else if (deg == 13){
                  App.getApp().setProperty("direction", "W");
                } else if (deg == 14){
                  App.getApp().setProperty("direction", "WNW");
                } else if (deg == 15){
                  App.getApp().setProperty("direction", "NW");
                } else if (deg == 16){
                  App.getApp().setProperty("direction", "NNW");
                } else if (deg == 17){
                  App.getApp().setProperty("direction", "N");
                } else {
                  App.getApp().setProperty("direction", "-");
                }
              }
            }
                        System.println("direction " + App.getApp().getProperty("direction"));

            var icon = data.get("icon");
            if (openWeather){
              if (icon.equals("01d")) {
                  // clear
                  App.getApp().setProperty("icon", "H");
              } else if (icon.equals("02d")) {
                  // cloudy
                  App.getApp().setProperty("icon", "G");
              } else if (icon.equals("03d")) {
                  // partly cloudy
                  App.getApp().setProperty("icon","B");
              } else if (icon.equals("04d")) {
                  // broken clouds
                  App.getApp().setProperty("icon", "I");
              } else if (icon.equals("09d")) {
                // shower rain
                  App.getApp().setProperty("icon", "E");
              } else if (icon.equals("10d")) {
                  // rain
                  App.getApp().setProperty("icon", "D");
              } else if (icon.equals("11d")) {
                  // thunderstorm
                  App.getApp().setProperty("icon", "C");
              } else if (icon.equals("13d")) {
                  // snow
                  App.getApp().setProperty("icon", "F");
              } else if (icon.equals("50d")) {
                  // mist
                  App.getApp().setProperty("icon", "A");
              } else if (icon.equals("01n")) {
                  // clear
                  App.getApp().setProperty("icon", "f");
              } else if (icon.equals("02n")) {
                  // cloudy
                  App.getApp().setProperty("icon", "g");
              } else if (icon.equals("03n")) {
                  // partly cloudy
                  App.getApp().setProperty("icon", "h");
              } else if (icon.equals("04n")) {
                  // broken clouds
                  App.getApp().setProperty("icon", "I");
              } else if (icon.equals("09n")) {
                // shower rain
                  App.getApp().setProperty("icon", "d");
              } else if (icon.equals("10n")) {
                  // rain
                  App.getApp().setProperty("icon", "c");
              } else if (icon.equals("11n")) {
                  // thunderstorm
                  App.getApp().setProperty("icon", "b");
              } else if (icon.equals("13n")) {
                  // snow
                  App.getApp().setProperty("icon", "e");
              } else if (icon.equals("50n")) {
                  // mist
                  App.getApp().setProperty("icon", "a");
              } else {  
                  // not set
                  App.getApp().setProperty("icon", "");
              }
//              if (icon == null) {
//                  App.getApp().setProperty("icon", 7);
//              } else if (icon.equals("01d") || icon.equals("01n")) {
//                  // clear
//                  App.getApp().setProperty("icon", 0);
//             } else if (icon.equals("09d") || icon.equals("09n") || icon.equals("10d") || icon.equals("10n")) {
//                // rain
//                  App.getApp().setProperty("icon", 1);
//              } else if (icon.equals("03d") || icon.equals("03n") || icon.equals("04d") || icon.equals("04n")) {
//                  // partly cloudy
//                  App.getApp().setProperty("icon", 2);
//              } else if (icon.equals("02d") || icon.equals("02n")) {
//                  // cloudy
//                  App.getApp().setProperty("icon", 3);
//             } else if (icon.equals("11d") || icon.equals("11n")) {
//                  // thunderstorm
//                  App.getApp().setProperty("icon", 4);
//              } else if (icon.equals("13d") || icon.equals("13n")) {
//                  // snow
//                  App.getApp().setProperty("icon", 6);
//              } else {  
//                  // not set
//                  App.getApp().setProperty("icon", 7);
//              }
            } else {
              if (icon == null) {
                  App.getApp().setProperty("icon", 7);
              } else if (icon.equals("clear-day") || icon.equals("clear-night")) {
                  App.getApp().setProperty("icon", 0);
              } else if (icon.equals("rain") || icon.equals("hail")) {
                  App.getApp().setProperty("icon", 1);
              } else if (icon.equals("cloudy")) {
                  App.getApp().setProperty("icon", 2);
              } else if (icon.equals("partly-cloudy-day") || icon.equals("partly-cloudy-night")) {
                  App.getApp().setProperty("icon", 3);
              } else if (icon.equals("thunderstorm")) {
                  App.getApp().setProperty("icon", 4);
              } else if (icon.equals("sleet")) {
                  App.getApp().setProperty("icon", 5);
              } else if (icon.equals("snow")) {
                  App.getApp().setProperty("icon", 6);
              } else {
                  App.getApp().setProperty("icon", 7);
              }
            }
          }
          WatchUi.requestUpdate();
      } 

    }

    function onSettingsChanged() {
        App.getApp().setProperty("sunrise", (sunRiseSet.computeSunrise(true) / 3600000));
        App.getApp().setProperty("sunset", (sunRiseSet.computeSunrise(false) / 3600000));
        WatchUi.requestUpdate();
    }
}