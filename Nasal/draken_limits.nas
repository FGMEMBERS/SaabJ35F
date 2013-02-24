# Nasal script to print errors to the screen when aircraft exceed design limits:
#  - extending gear above maximum gear extended speed
#  - exceeding Vna
#  - exceeding structural G limits

var checklimits = func {
  if (getprop("/sim/freeze/replay-state"))
    return;
    
  var msg = "";
  var g = getprop("/accelerations/pilot-gdamped") or 1;  
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

# Start
checklimits();
