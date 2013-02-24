#Included functions:
#Start up (start_up)
#Fuel control (fuel_handler)
#G watcher (g_watch)
#Cut-off reset after "neg-g" starvation (cutoff_reset)
#Autostart (autostart)
#Opening fuel valve autostart (waiting_n1)

#Debug setting
 var verbose = 1;
 var dropflag=0;

 var gnegt=-1;
 
#Cut-off reset
 var cutoff_reset = func {
   setprop("/controls/engines/engine[0]/cutoff", 0);
   if (verbose > 1) print("Reset fuel cut-off");
 }

#Fuel handling
 var fuel_handler = func {
   #Fuel starvation too long negative G
   if (gnegt > 0) {
      if (getprop("/sim/time/elapsed-sec") - gnegt > 16) {
         setprop("/controls/engines/engine[0]/throttle", 0.0);
         if (verbose > 0) print("Engine dying for lack of fuel.");
      }
      if (getprop("/sim/time/elapsed-sec") - gnegt > 19) 
         setprop("/controls/engines/engine[0]/cutoff", 1);
         settimer(cutoff_reset, 1);
   }
   #Switches beteeen external and internal tanks when external empties
   var drop1_n = getprop("/consumables/fuel/tank[1]/level-norm") or 0;
   var drop2_n = getprop("/consumables/fuel/tank[2]/level-norm") or 0;
   if (getprop("/consumables/fuel/using-droptanks")) {
      if (verbose > 1) print("Using droptanks, checking fuel status");
      if (drop1_n<0.05 and drop2_n<0.05) {
         setprop("/fdm/jsbsim/propulsion/tank[0]/priority", 1);
         if (verbose > 0 and dropflag == 0) {
            print("Droptanks emptying switched on internal.");
            dropflag=1;
         }
      }
      if (getprop("/consumables/fuel/tank[1]/empty") == 1 and getprop("/consumables/fuel/tank[2]/empty") == 1) 
      {
         setprop("/fdm/jsbsim/propulsion/tank[1]/priority", 0);
         setprop("/fdm/jsbsim/propulsion/tank[2]/priority", 0);
         if (verbose > 0 and getprop("/consumables/fuel/using-droptanks"))
            print("Droptanks empty and shut of. Only using internal");
         setprop("/consumables/fuel/using-droptanks", 0);
      }
   } else if (drop1_n > 0.05 or drop2_n > 0.05) {
      setprop("/fdm/jsbsim/propulsion/tank[0]/priority", 0);
      setprop("/fdm/jsbsim/propulsion/tank[1]/priority", 1);
      setprop("/fdm/jsbsim/propulsion/tank[2]/priority", 1);
      if (verbose > 0 and getprop("/consumables/fuel/using-droptanks")) 
         print("Fuel in droptanks. Using droptanks.");
      setprop("/consumables/fuel/using-droptanks", 1);
      dropflag=0;
   }
   # Sets fuel gauge needles rotation
   if (getprop("/consumables/fuel/using-droptanks")) {
       setprop("/instrumentation/fuel/needleF_rot", 
          getprop("/consumables/fuel/tank[1]/level-lbs")*0.248628692);
       setprop("/instrumentation/fuel/needleB_rot", 
          getprop("/consumables/fuel/tank[2]/level-lbs")*0.248628692);
   } else {
       setprop("/instrumentation/fuel/needleF_rot", 
          getprop("/consumables/fuel/tank[0]/level-lbs")*0.0447418375);
       setprop("/instrumentation/fuel/needleB_rot", 
          getprop("/consumables/fuel/tank[0]/level-lbs")*0.0447418375);
   }
   settimer(fuel_handler, 3);
 }

#G-watcher for fuel and G-gauge
 var g_watch = func {
    var g = getprop("/accelerations/pilot-gdamped") or 1;
    if (g > getprop("/instrumentation/g-max")) {
       setprop("/instrumentation/g-max", g < 11.5 ? g : 11.5);
       if (verbose > 1) print("G-max rised");
    }
    if (gnegt < 0) {
       if (g < 0) {
          gnegt= getprop("/sim/time/elapsed-sec") or 0;
          if (verbose > 1) print("Detected negative G");
       }
    } else {
       if (g > 0) gnegt = -1;
       if (verbose > 1) print("End of negative G");
    }
    settimer(g_watch, 0.1);
 }

# Opens fuel valve in autostart
 var waiting_n1 = func {
  if (verbose > 1) print("Autostart engaged");
  if (getprop("/engines/engine[0]/n1") > 5.2) {
    setprop("/controls/engines/engine[0]/cutoff", 0);
    if (verbose > 0) print("Ignited");
  } else settimer(waiting_n1, 1);
 }

#Simulating autostart function
 var autostart = func {
  if (verbose > 0) print("Initializing Autostart");
  if (getprop("/velocities/groundspeed-kt") < 1e-3){
    setprop("/controls/engines/engine[0]/cutoff", 1);
    setprop("/controls/engines/engine[0]/starter", 1);
    settimer(waiting_n1, 1);
  }
 }

 var drop = func {
    setprop("/fdm/jsbsim/propulsion/tank[0]/priority", 1);
    setprop("/fdm/jsbsim/propulsion/tank[1]/priority", 0);
    setprop("/fdm/jsbsim/propulsion/tank[2]/priority", 0);
    setprop("fdm/jsbsim/inertia/pointmass-weight-lb", 0);
    setprop("/consumables/fuel/tank[1]/level-lbs", 0);
    setprop("/consumables/fuel/tank[2]/level-lbs", 0);
    setprop("/consumables/fuel/using-droptanks", 0);
    setprop("/consumables/droptanks", 0);
    if (verbose > 0)print("Droptanks shut off and ejected. Using internal fuel");
 }

 var add = func {
    setprop("/consumables/fuel/tank[1]/level-lbs", 942);
    setprop("/consumables/fuel/tank[2]/level-lbs", 942);
    setprop("fdm/jsbsim/inertia/pointmass-weight-lb", 200);
    setprop("/fdm/jsbsim/propulsion/tank[1]/priority", 1);
    setprop("/fdm/jsbsim/propulsion/tank[2]/priority", 1);
    setprop("/fdm/jsbsim/propulsion/tank[0]/priority", 0);
    setprop("/consumables/fuel/using-droptanks", 1);
    setprop("/consumables/droptanks", 1);
    if (verbose > 0)print("Droptanks attached and connected. Fuel from droptanks");
 }

#Handle droptanks
 var drophandle = func(pilot) {
    if (pilot) {
       if (getprop("fdm/jsbsim/gear/unit[0]/compression-ft") > 0.05) {
         if (verbose > 0) print("Can not eject droptanks on ground"); 
         return;
       }  
       drop();       
    } else {
       if (getprop("/velocities/groundspeed-kt") < 1e-3 and 
              getprop("/controls/engines/engine[0]/cutoff") == 1) {
          if (getprop("/consumables/fuel/using-droptanks")) drop(); else add();
       } else {
          if (verbose > 0) print("Can not handle droptanks unless fuel cutoff and stationary.");
       }
    }
 }

 var warning_on = func {
     setprop("/instrumentation/gear_warning", 0);
     settimer(gear_watch, 0.5);
 }

#Gear warning light
 var gear_watch = func {
   var gp = getprop("/gear/gear[0]/position-norm");
   if ((gp > 0 and gp < 1) or (gp == 0 and getprop("instrumentation/airspeed-indicator/indicated-speed-kt") < 243 and
       getprop("/instrumentation/altimeter/indicated-altitude-ft") < 4700 and
       getprop("/controls/engines/engine[0]/throttle") < 0.85)) {
          setprop("/instrumentation/gear_warning", 1);
          settimer(warning_on, 0.5);
   } else {
      setprop("/instrumentation/gear_warning", 0);
      settimer(gear_watch, 2);
   }
 }

#Alt indicator watch
 var alt_watch = func {
   var target=getprop("/autopilot/settings/target-altitude-m");
   if ( target > 0 ) {
     var h=getprop("/instrumentation/altimeter/indicated-altitude-ft")*0.305;
     var vs=getprop("/instrumentation/vertical-speed-indicator/indicated-speed-fpm");
     vs = vs < 0 ? -vs : vs ;
     if (h-target>-15 and h-target<15 and vs < 3) 
        setprop("/instrumentation/alt_indicator", 1);
     else setprop("/instrumentation/alt_indicator", 
                  1- getprop("/instrumentation/alt_indicator"));
     settimer(alt_watch, 0.5);
   } else {
     setprop("/instrumentation/alt_indicator", 0);
     settimer(alt_watch, 3);
   }
 }
  
#Start up script to initiate functions
 var start_up  = func {
  setprop("/instrumentation/g-max", 0);
  fuel_handler();
  print("Fuel ... Check");
  g_watch();
  print("G-gauge ... Check");
  gear_watch();
  print("Gears ... Check");
  settimer(alt_watch, 3);
  print("Autopilot ... Check");
 }


start_up();
