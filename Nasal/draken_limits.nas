# Nasal script to print errors to the screen when aircraft exceed design limits:
#  - extending gear above maximum gear extended speed
#  - exceeding Vna
#  - exceeding structural G limits

var checklimits = func {
  if (getprop("/sim/freeze/replay-state"))
    return;
    
  var msg = "";
  var g = getprop("/accelerations/pilot-gdamped") or 0;  
  var airspeed = getprop("velocities/airspeed-kt") or 0;
  if (getprop("controls/gear/gear-down") == 1 and 
     airspeed > getprop("limits/max-gear-extended-speed"))
  {
    msg = ("Gear extended above maximum extended speed!");
  }
  
  if (g > getprop("limits/max-positive-g"))
  {
    msg = "Airframe structural positive-g load limit exceeded!";
  }

  if (g < getprop("limits/max-negative-g"))
  {
    msg = "Airframe structural negative-g load limit exceeded!";
  }

  if (airspeed > getprop("limits/vne"))
  {
    msg = "Airspeed exceeds Vne!";
  }

  if (msg != "")
  {
    # If we have a message, display it, but don't bother checking for
    # any other errors for 10 seconds. Otherwise we're likely to get
    # repeated messages.
    screen.log.write(msg);
    settimer(checklimits, 10);
  }
  else
  {
    settimer(checklimits, 1);
  }
}

var testTouchDown = func(n) {
   var wow = n.getValue() or 0.0;
   var dn_spd = getprop("/velocities/speed-down-fps")*60;
   if (wow and dn_spd > getprop("limits/max-touch-down-fpm")){
      screen.log.write("Touch down vertical speed to high!");
   }
}

var testDroptanks = func(n) {
   var drp = n.getValue() or 0.0;
   var airspeed = getprop("instrumentation/airspeed-indicator/indicated-mach") or 0;
   if (drp==0 and airspeed > getprop("limits/max-drop-speed-mach")){
      screen.log.write("Droptank eject speed exceeded!");
   }
}


# Start
checklimits();
setlistener("/gear/gear[0]/wow", testTouchDown, 0, 0);
setlistener("/gear/gear[1]/wow", testTouchDown, 0, 0);
setlistener("/gear/gear[2]/wow", testTouchDown, 0, 0);
setlistener("/gear/gear[3]/wow", testTouchDown, 0, 0);
setlistener("/consumables/droptanks", testDroptanks, 0, 0);

