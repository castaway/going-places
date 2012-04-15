var GP = (GP) ? GP : {};

GP.circle_style = {
    fillColor: '#000',
    fillOpacity: 0.1,
    strokeWidth: 0
};

GP.default_loc = {
    latitude: 51.56,
    longitude: -1.78
};

GP.log = function(message) {
    if(0) {
        var log = jQuery('#log');
        log.append(message);
    }
}

if(!GP.update_location) {
    GP.update_location = function(event) {
        // Do/can we show other users later on this layer?

        GP.log('<p>Opened log</p>');
        GP.user_layer.removeAllFeatures();
        GP.log('<p>removed existing features</p>');

        var circle = new OpenLayers.Feature.Vector(
            OpenLayers.Geometry.Polygon.createRegularPolygon(
                new OpenLayers.Geometry.Point(event.point.x, event.point.y),
                event.position.coords.accuracy ,
//                event.position.coords.accuracy/2,
                40,
                0
            ),
            {},
            GP.circle_style
        );
//        jQuery('#stats').innerHTML("Accuracy: " + event.position.coords.accuracy);
        GP.log('<p>Created circle</p>');
        GP.log('<p>units: '+GP.map.getUnits()+'</p>');
        GP.log('<p>accuracy: ' + event.position.coords.accuracy + '</p>');

        try {
          GP.user_layer.addFeatures([
                                      new OpenLayers.Feature.Vector(
                                        event.point,
                                        {},
                                        {                    
                                          graphicName: 'cross',
                                          strokeColor: '#f00',
                                          strokeWidth: 2,
                                          fillOpacity: 0,
                                          pointRadius: 10
                                        }
                                      ),
                                      circle
                                    ]);          
        } catch (error) {
          GP.log('<p>error doing addFeature: '+error+'</p>');
        }
        GP.log('<p>added vector and circle to user_layer</p>');
//        GP.map.zoomToExtent(GP.user_layer.getDataExtent());
        this.bind = true;
    };
}

if(!GP.latlon_to_map) {
    GP.latlon_to_map = function(latlon) {
        var lonlat = new OpenLayers.LonLat(latlon.longitude, latlon.latitude).transform(
            new OpenLayers.Projection("EPSG:4326"),
            GP.map.getProjectionObject()
        );
        return lonlat;
    };
}

GP.on_popup_close = function(event) {
                // 'this' is the popup.
    GP.select_control.unselect(this.feature);
};

GP.on_feature_select = function (event) {
    var feature = event.feature;
    GP.popup = new OpenLayers.Popup.FramedCloud("featurePopup",
                                                 feature.geometry.getBounds().getCenterLonLat(),
                                                 new OpenLayers.Size(100,100),
                                                 "<h2>"+feature.attributes.title + "</h2>"
//                                                 + feature.attributes.description,
                                                ,null, true, GP.on_popup_close);
    feature.popup = GP.popup;
    GP.popup.feature = feature;
    GP.map.addPopup(GP.popup);
};

GP.on_feature_unselect = function (event) {
    var feature = event.feature;
    if (feature.popup) {
        GP.popup.feature = null;
        GP.map.removePopup(feature.popup);
        feature.popup.destroy();
        feature.popup = null;
    }
};


jQuery(document).ready(function() {
  GP.map = new OpenLayers.Map('map');
  GP.log('Map units: ' + GP.map.units);

  GP.map.addControl(new OpenLayers.Control.LayerSwitcher());
  GP.map.addLayer(new OpenLayers.Layer.OSM("OSM (Standard)"));

/*
  GP.places_layer = new OpenLayers.Layer.Markers("Markers");
  GP.map.addLayer(GP.places_layer);
*/
  GP.user_layer = new OpenLayers.Layer.Vector('vector');
  GP.map.addLayer(GP.user_layer);

  var places_style_map = new OpenLayers.StyleMap({
      "default": new OpenLayers.Style({
          graphicName: 'x',
          pointRadius: 10,
          fillColor: "#ffcc66",
          strokeColor: "#ff9933",
          strokeWidth: 2,
          graphicZIndex: 1
      }),
      "select": new OpenLayers.Style({
          fillColor: "#66ccff",
          strokeColor: "#3399ff",
          graphicZIndex: 2
      })
  });
    
  // I would like this eventually to only update if the user has moved N metres?
  GP.places_layer = new OpenLayers.Layer.Vector("GP Places", {
      projection: GP.map.displayProjection,
      strategies: [new OpenLayers.Strategy.BBOX({resFactor: 1.1, })],
      protocol: new OpenLayers.Protocol.HTTP({
          url: "/cgi-bin/geotrader.cgi/places",
          format: new OpenLayers.Format.Text({
              //defaultStyle: {},
              extractStyles: false
          }
                                            )
          //          format: new OpenLayers.Format.Text({ defaultStyle: { graphicName: 'x' } })
      }),
      styleMap: places_style_map
      //style: { graphicName: 'x' }
  }); 
  GP.map.addLayer(GP.places_layer);

    // Interaction; not needed for initial display.
    GP.select_control = new OpenLayers.Control.SelectFeature(GP.places_layer);
    GP.map.addControl(GP.select_control);
    GP.select_control.activate();
    GP.places_layer.events.on({
        'featureselected': GP.on_feature_select,
        'featureunselected': GP.on_feature_unselect
    }); 

  GP.map.setCenter(GP.latlon_to_map(GP.default_loc), 15);

  // Allow user to adjust the accuracy/maxage etc?
  GP.geolocate = new OpenLayers.Control.Geolocate({
    bind: false,
    geolocationOptions: {
        enableHighAccuracy: true,
        maximumAge: 10, // seconds
        timeout: 20000   // miliseconds 
    }
  });
  GP.map.addControl(GP.geolocate);

  GP.geolocate.watch = true;
  GP.geolocate.events.register("locationupdated", GP.geolocate, GP.update_location);

    GP.geolocate.events.register("locationfailed", this, function() {
//        console.log('Location detection failed');
//        alert('Location detection failed');
//        GP.geolocate.deactivate();
    });

    GP.geolocate.events.register("locationuncapable", this, function() {
        console.log('Location detection not possible');
        alert('Location detection not possible');
        GP.geolocate.deactivate();
    });

    GP.geolocate.activate();
} );