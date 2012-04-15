window.onload = get_my_location;

function get_my_location() {
    if(navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(display_location, location_error);
    } else {
        alert("No geolocation support");
    }
}

function display_location(position) {
    var latitude = position.coords.latitude;
    var longitude = position.coords.latitude;

    var mydiv = document.getElementById('location');
    mydiv.innerHTML = "You are at Latitude: " + latitude + ", Longitude: " + longitude;
}

function location_error(error) {
    var errorTypes = {
        0: 'Unknown error',
        1: 'Permission denied by user',
        2: 'Position not available',
        3: 'Request timed out'
    };

    var error_msg = errorTypes[error.code];
    if(error.code == 0 || error.code == 2) {
        error_msg = error_msg + " " + error.message;
    }

    document.getElementById("location").innerHTML = error_msg;
}