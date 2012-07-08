var GP = (GP) ? GP : {

// Features within this distance of user's current position are deemed to be "close by"
    MAX_DIST: 50, // metres

// Default map centre
    default_loc: {
        latitude: 51.56,
        longitude: -1.78
    },

// Style for Geo-accuracy circle arround current-point cross.
    circle_style: {
        fillColor: '#000',
        fillOpacity: 0.1,
        strokeWidth: 0
    },
    settings: {
        // Keep track of the users actual position
        tracking: true,
        // Update the users position on the map
        following: true
    },
// collect currently visible features, set when update_location is called
    visible_features: {}
};

// Append log messages to on-screen div for mobile debugging
GP.log = function(message) {
    if(0) {
        var log = jQuery('#log');
        log.append(message);
    }
}

if(!GP.update_take_button) {
    GP.update_take_button = function(card_state) {
        console.log(card_state);
        alert(card_state);
    };
}

if(!GP.take_card) {
    GP.take_card = function() {
        // animate card?

        jQuery.post(
            '/cgi-bin/geotrader.cgi/_take_card',
            { card_id: GP.card.id },
            GP.update_take_button
        );
        
        // timeout 
    };
}

// Everytime the GPS reports a new location, redraw the users position on the 
// map, and re-centre the map to that position.
// If settings.following is false, only store the current position, don't update the map.
if(!GP.update_location) {
    GP.update_location = function(event) {
        // Do/can we show other users later on this layer?

        GP.current_position = {
            point: event.point,
            last_updated: Date.now()
        };

        if(GP.settings.following) {
            GP.user_layer.removeAllFeatures();

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
            //        GP.map.zoomToExtent(GP.user_layer.getDataExtent());

            GP.highlight_close_features(event.point);

            this.bind = true;
        }
    };
}

GP.highlight_close_features = function(my_loc) {
//    GP.log("<p>Looking near: " + my_loc + '</p>');

    var my_point = new OpenLayers.Geometry.Point(my_loc.x, my_loc.y);

//    GP.log("<p>Looking near: " + my_point + '</p>');
    var features = GP.places_layer.features; 
//    GP.log("<p>Got features</p>");
    var is_changed = false;

    // Empty / refresh current visible features array, if any
    GP.visible_features = {};
    for (i=0; i<features.length; i++) {
      //  GP.log("Dist: " + my_point.distanceTo(features[i].geometry) + '<br/>');
      if(my_point.distanceTo(features[i].geometry) <= GP.MAX_DIST) {
          GP.log("<p>Found " + features[i].geometry + '</p>');

          // See StyleMap for 'nearby' below
     //     GP.places_layer.features[i].renderIntent = "nearby";
          GP.places_layer.features[i].attributes.proximity = "near";

          // Need to hide all the other ones we showed previously?
          // Store by internal id so we can easily re-find them?
          GP.visible_features[features[i].attributes.id] = features[i];

// This doesn't work if there are more than one!
//          GP.show_card(features[i]);
          is_changed = true;
        }
    }

    if(is_changed) {
        GP.places_layer.redraw();
        GP.store_location(my_loc);
    }

};

GP.on_feature_added = function(obj) {
    if(GP.visible_features[obj.feature.attributes.id]) {
        obj.feature.attributes.proximity = "near";
    }
}

// Popup a particular feature
GP.show_card = function(card_feature) {
    if(GP.popup && GP.popup.feature) {
        GP.select_control.unselect(GP.popup.feature);
    }
    GP.on_feature_select({ feature: card_feature });
    jQuery('#card-'+card_feature.attributes.id).show();
}

// Callback to the backend using ajax/post to store the users current location
// Should only be called when there is something interesting happening
GP.store_location = function(point) {
    var latlon = new OpenLayers.LonLat(point.x, point.y).transform(
        GP.map.getProjectionObject(),
        new OpenLayers.Projection("EPSG:4326")
    );

    jQuery.post(
        '/cgi-bin/geotrader.cgi/_update_location',
        { lat: latlon.lat, lon: latlon.lon }
    );
}

// Convert a location from latlon to map projection coords
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
    GP.popup = new OpenLayers.Popup.FramedCloud(
        "featurePopup",
        feature.geometry.getBounds().getCenterLonLat(),
        new OpenLayers.Size(100,100),
        "<h2>"+feature.attributes.title + 
            " (" + feature.attributes.id + ")" +
            "</h2>"
            + feature.attributes.description
        ,null, true, GP.on_popup_close);
    feature.popup = GP.popup;
    GP.popup.feature = feature;
    GP.map.addPopup(GP.popup);

    if(GP.visible_features[feature.attributes.id]) {
        jQuery('#card-'+feature.attributes.id).show();
    }
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

GP.setup_map = function() {
  GP.map = new OpenLayers.Map('map');
  GP.log('Map units: ' + GP.map.units);

  GP.map.addControl(new OpenLayers.Control.LayerSwitcher());
  GP.map.addLayer(new OpenLayers.Layer.OSM("OSM (Standard)"));

  GP.user_layer = new OpenLayers.Layer.Vector('vector');
  GP.map.addLayer(GP.user_layer);

  var proximity_styles = {
      "far": { fillColor: "#ffcc66" },
      "near": { fillColor: "#00FF00" },
      "owned": { fillColor: "#888888" }
  };

  var places_style_map = new OpenLayers.StyleMap({
      "default": new OpenLayers.Style({
          graphicName: 'x',
          pointRadius: 10,
//          fillColor: "#ffcc66",
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
  places_style_map.addUniqueValueRules("default", "proximity", proximity_styles);
    
  // I would like this eventually to only update if the user has moved N metres?
  GP.places_layer = new OpenLayers.Layer.Vector("GP Places", {
      projection: GP.map.displayProjection,
      strategies: [new OpenLayers.Strategy.BBOX({resFactor: 1.3, })],
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
        'featureunselected': GP.on_feature_unselect,
        'beforefeatureadded': GP.on_feature_added
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
};


jQuery(document).ready(function() {
    GP.setup_map();

    jQuery('#toggle_tracking').change(function() {
        GP.settings.tracking = !GP.settings.tracking;
        GP.geolocate.bind = GP.settings.tracking;
        GP.geolocate.watch = GP.settings.tracking;
    }); 

    jQuery('#toggle_following').change(function() {
        GP.settings.following = !GP.settings.following;
        GP.geolocate.bind = GP.settings.following;
//        alert(" setting is now " + GP.settings.following);
    });

    // Do we "reserve" the card while the user is looking at the page
    // in case of multiple people standing here?
    jQuery('#take_card').click(function() {
        // ajax, plus replace button, some sorta animation to "hand"?
        GP.take_card();
        return false;
    });


    jQuery('#register_button,#login_button').click(function() {
        jQuery('#register_form,#login_form').toggleClass('visible hidden');
        return false;
    });
});

