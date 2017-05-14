#Included functions:
#Start up (start_up)
#Fuel control (fuel_handler)
#G watcher (g_watch)
#Autostart (autostart)
#Opening fuel valve autostart (waiting_n1)
#Autopilot settings (auto_setting(set))
#Handle droptanks (drophandle)
#Gear warning light (gear_watch)
#Alt indicator watch (alt_watch)
#Autopilot locks (auto_settings)
#Canopy operation (canopy_operate)
#Light intensity setter (light_intens)
#Start up

#Debug setting
 var verbose = 1;
 
 var gnegt=-1;
 var active_tank=0;
 var inactive_tank=3;
 var t1=0;
 var t2=3;
 var auto_gen=0;

#Fuel handling helper function
 var choose_tank = func(tank1,tank2) {
   var ff=getprop("engines/engine[0]/fuel-flow_pph") or 0;
   if (ff > 17000) {
     setprop("/fdm/jsbsim/propulsion/tank["~tank1~"]/collector-valve", 1);
     setprop("/fdm/jsbsim/propulsion/tank["~tank2~"]/collector-valve", 1);
   } else {
       var atl=getprop("consumables/fuel/tank["~active_tank~"]/level-lbs");   
       if (atl+50 < getprop("consumables/fuel/tank["~inactive_tank~"]/level-lbs") or atl < 1) {
         var tmp=active_tank;
         active_tank=inactive_tank;
         inactive_tank=tmp;
       }
     setprop("/fdm/jsbsim/propulsion/tank["~active_tank~"]/collector-valve", 1);
     setprop("/fdm/jsbsim/propulsion/tank["~inactive_tank~"]/collector-valve", 0);     
   }
 }

 var use_drop = func {
   if (getprop("/instrumentation/switches/drop_selector/pos") and
      (getprop("/consumables/fuel/tank[1]/empty") != 1 or 
       getprop("/consumables/fuel/tank[2]/empty") != 1)) {
     setprop("/fdm/jsbsim/propulsion/tank[0]/collector-valve", 0);
     setprop("/fdm/jsbsim/propulsion/tank[3]/collector-valve", 0);
      t1=1;
      t2=2;
      active_tank=1;
      inactive_tank=2;
      setprop("/consumables/fuel/using-droptanks", 1);
      if (verbose > 0 and getprop("/consumables/fuel/using-droptanks")) 
         print("Fuel in droptanks. Using droptanks.");
   } else use_internal();   
 }
 
 var use_internal = func { 
   setprop("/fdm/jsbsim/propulsion/tank[1]/collector-valve", 0);
   setprop("/fdm/jsbsim/propulsion/tank[2]/collector-valve", 0);
   setprop("/consumables/fuel/using-droptanks", 0);
   t1=0;
   t2=3;
   active_tank=0;
   inactive_tank=3;
   if (verbose > 1) print("Using internal tanks.");
 }
 
#Fuel handling
 var fuel_handler = func {
   #Switches beteeen external and internal tanks when external empties
   if (getprop("/consumables/fuel/using-droptanks")) {
      if (verbose > 1) print("Using droptanks, checking fuel status");
      if (getprop("/consumables/fuel/tank[1]/empty") and 
          getprop("/consumables/fuel/tank[2]/empty")) {
         use_internal();
         if (verbose > 0) {
            print("Droptanks empty switched on internal.");
         }
      }
   }
   choose_tank(t1,t2);
   # Sets fuel gauge needles rotation
   if (getprop("/consumables/fuel/using-droptanks")) {
       setprop("/instrumentation/fuel/needleF_rot", 
          getprop("/consumables/fuel/tank[1]/level-lbs")*0.248628692);
       setprop("/instrumentation/fuel/needleB_rot", 
          getprop("/consumables/fuel/tank[2]/level-lbs")*0.248628692);
   } else {
       setprop("/instrumentation/fuel/needleF_rot", 
          getprop("/consumables/fuel/tank[0]/level-lbs")*0.097396697);
       setprop("/instrumentation/fuel/needleB_rot", 
          getprop("/consumables/fuel/tank[3]/level-lbs")*0.097396697);
   }
   #FT_light check
   if (getprop("/consumables/droptanks")) {
     if (getprop("/instrumentation/switches/drop_selector/pos") and 
         getprop("/instrumentation/switches/fuel/pos")) 
       setprop("/instrumentation/fuel/FT_light", 0);
     else if (getprop("/consumables/fuel/tank[1]/empty") and 
              getprop("/consumables/fuel/tank[2]/empty") and 
              getprop("/gear/gear[0]/wow") == 0)
       setprop("/instrumentation/fuel/FT_light", 0);
     else setprop("/instrumentation/fuel/FT_light", 1);
   } else setprop("/instrumentation/fuel/FT_light", 0);
   #LT light check
   if (getprop("/instrumentation/switches/fuel/pos") and
       getprop("fdm/jsbsim/propulsion/afterburner-pump"))
     setprop("/instrumentation/fuel/LT_light", 0);
   else setprop("/instrumentation/fuel/LT_light", 1); 
   settimer(fuel_handler, 0.2);
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
  if (getprop("/engines/engine[0]/n1") < 5.2) settimer(waiting_n1, 1);
  else if (getprop("/engines/engine[0]/n1") < 27) {
    setprop("/controls/engines/engine[0]/cutoff", 0);
    settimer(waiting_n1, 1);
  } else {
    if (auto_gen == 1) {
      setprop("controls/electric/engine[0]/generator", 1);
      if (verbose > 1) print("Generator on");
      auto_gen=0;
      if (verbose > 0) print("Running");
    }
  }
 }

#Simulating autostart function
 var autostart = func {
  if (verbose > 0) print("Initializing Autostart");
  if (getprop("/velocities/groundspeed-kt") < 1e-3 and
      getprop("controls/electric/engine[0]/generator") == 0){
    setprop("/controls/engines/engine[0]/cutoff", 1);
    setprop("/controls/engines/engine[0]/starter", 1);
    settimer(waiting_n1, 1);
  }
 }

#Drop tank handling helper functions

 var air_caution = func {
   setprop("consumables/fuel/pressure-fail", 1-getprop("consumables/fuel/pressure-fail"));
   if (getprop("consumables/fuel/pressure-fail") == 1) settimer(air_caution, 0.5);
 }
 
 
 var drop = func {
    setprop("/fdm/jsbsim/propulsion/tank[1]/collector-valve", 0);
    setprop("/fdm/jsbsim/propulsion/tank[2]/collector-valve", 0);
    setprop("fdm/jsbsim/inertia/pointmass-weight-lb", 0);
    setprop("/consumables/fuel/tank[1]/level-lbs", 0);
    setprop("/consumables/fuel/tank[2]/level-lbs", 0);
    setprop("/consumables/fuel/using-droptanks", 0);
    setprop("/consumables/droptanks", 0);
    use_internal();
    if (verbose > 0)print("Droptanks shut off and ejected. Using internal fuel");
    air_caution();
 }

 var add = func {
    setprop("/consumables/fuel/tank[1]/level-lbs", 942);
    setprop("/consumables/fuel/tank[2]/level-lbs", 942);
    setprop("fdm/jsbsim/inertia/pointmass-weight-lb", 200);
    setprop("/consumables/droptanks", 1);
    use_drop();
    air_caution();
 }

#Handle droptanks
 var drophandle = func(pilot) {
    if (pilot) {
       if (getprop("/gear/gear[0]/wow") > 0.05) {
         if (verbose > 0) print("Can not eject droptanks on ground"); 
         return;
       }
       if (getprop("/consumables/droptanks")) {
         setprop("/rendering/submodels/dropL", 1);
         setprop("/rendering/submodels/dropR", 1);
       }
       drop();
    } else {
       if (getprop("/velocities/groundspeed-kt") < 1e-3 and 
              getprop("/instrumentation/switches/drop_selector/pos") == 0) {
          if (getprop("/consumables/droptanks")) {
            drop(); 
            screen.log.write("Droptanks shut off and removed");
          } else {
            add();
            screen.log.write("Droptanks attached and connected");
          }
       } else {
          screen.log.write("Can not handle droptanks unless fuel D/T valve closed and stationary.");
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
   var target=getprop("/autopilot/settings/target-altitude-ft");
   if (getprop("/autopilot/locks/altitude") and getprop("controls/electric/engine[0]/generator") == 1) {
     var h=getprop("/instrumentation/altimeter/indicated-altitude-ft");
     var dh=7765/getprop("/systems/static/pressure-inhg");
     var vs=getprop("/instrumentation/vertical-speed-indicator/indicated-speed-fpm");
     vs = vs < 0 ? -vs : vs ;
     if (h-target>-dh and h-target<dh and vs < 600 and !getprop("/autopilot/altoff") ) 
        setprop("/instrumentation/alt_indicator", 1);
     else setprop("/instrumentation/alt_indicator", 
                  1- getprop("/instrumentation/alt_indicator"));
     settimer(alt_watch, 0.5);
   } else {
     setprop("/instrumentation/alt_indicator", 0);
     settimer(alt_watch, 3);
   }
 }

#Handels autopilot locks
var auto_setting = func(set) {
  if (getprop("/autopilot/enabled")) {
    if (set == "alt") {
      if (getprop("/autopilot/locks/altitude"))  setprop("/autopilot/locks/altitude", 0);
      else {
        setprop("/autopilot/locks/damp", 1);
        setprop("/autopilot/locks/attitude", 0);
        setprop("/autopilot/locks/altitude", 1);
      }
    }
    else if (set == "att") {
      if (getprop("/autopilot/locks/attitude"))  setprop("/autopilot/locks/attitude", 0);
      else {
        setprop("/autopilot/locks/damp", 1);
        setprop("/autopilot/locks/altitude", 0);
        setprop("/autopilot/locks/attitude", 1);
      }
    }
    else if (set == "dmp") {
      if (getprop("/autopilot/locks/damp") == 0) {
        setprop("/autopilot/locks/damp", 1);
        setprop("/fdm/jsbsim/fcs/yaw-damper-enable", 1);
        setprop("fdm/jsbsim/fcs/pitch-damper-enable", 1);
      } else {
        setprop("/autopilot/locks/damp", 0);
        setprop("/fdm/jsbsim/fcs/yaw-damper-enable", 0);
        setprop("fdm/jsbsim/fcs/pitch-damper-enable", 0);
        setprop("/autopilot/locks/altitude", 0);
        setprop("/autopilot/locks/attitude", 0);
      }
    }
  }
}

var autoOnOff = func(n) {
  var on = n.getValue();
  print(on);
  if (on == 1) {
    setprop("/autopilot/locks/damp", 1);
    setprop("/fdm/jsbsim/fcs/yaw-damper-enable", 1);
    setprop("fdm/jsbsim/fcs/pitch-damper-enable", 1);
  } else {
    setprop("/autopilot/locks/damp", 0);
    setprop("/fdm/jsbsim/fcs/yaw-damper-enable", 0);
    setprop("fdm/jsbsim/fcs/pitch-damper-enable", 0);
    setprop("/autopilot/locks/altitude", 0);
    setprop("/autopilot/locks/attitude", 0);
  }
} 

#Canopy operation
var canopy_operate = func {
  if (getprop("/controls/canopy/position-norm") > 0) {
    canopy.toggle();
    setprop("/controls/canopy/control", 1-getprop("/controls/canopy/control"));
  } else {
    if (canopy_opening == 0) {
      if (getprop("/controls/canopy/enabled")) setprop("/controls/canopy/enabled", 0);
      else {
        setprop("/controls/canopy/enabled", 1);
        canopy_opening=1;
      } 
    } else {
      canopy.toggle();
      setprop("/controls/canopy/control", 1-getprop("/controls/canopy/control"));
      canopy_opening=0;
    }
  }
}


#Light intensity setter
 var light_intens = func {
    var sa = getprop("/sim/time/sun-angle-rad") or 1;
    var ns = getprop("/controls/lighting/nav-lights-setting") or 0;
    var i= sa > 1.58 ? sa/4+0.315 : sa/10+0.443 ;
    setprop("/rendering/lights-factor", i);
    setprop("/rendering/nav-lights-factor", i/2.2*ns);
    settimer(light_intens, 0.5);
 }

# Switch LT fuel valve
 var lt_switch_toggle = func {
   setprop("/fdm/jsbsim/propulsion/tank[4]/priority", 
           1-getprop("/fdm/jsbsim/propulsion/tank[4]/priority"));
   setprop("/fdm/jsbsim/propulsion/tank[5]/priority", 
           1-getprop("/fdm/jsbsim/propulsion/tank[4]/priority"));
   setprop("instrumentation/switches/fuel/pos", 1-getprop("instrumentation/switches/fuel/pos"));
   fuel_cover.toggle();   
 }
# Autostart aircraft
 var start_systems = func {
   setprop("controls/electric/battery-switch", 1);
   #Canopy
   if (getprop("/controls/canopy/enabled") and 
       getprop("/controls/canopy/position-norm") == 0)
     canopy_operate();
   # Tanks and valves
   setprop("/fdm/jsbsim/propulsion/tank[4]/priority", 1);
   setprop("/fdm/jsbsim/propulsion/tank[5]/priority", 1);
   setprop("instrumentation/switches/fuel/pos", 1);
   setprop("/fdm/jsbsim/propulsion/afterburner-pump", 1);
   if (getprop("/consumables/droptanks")) 
       setprop("/instrumentation/switches/drop_selector/pos", 1);
   auto_gen=1;
   #Radio
   setprop("/instrumentation/fr21/pwr", 1);
   button_handlerAK("A");
   button_handler15("b1");
   autostart();
 } 
  
#Start up script to initiate functions
 var start_up  = func {
  aircraft.livery.init("Aircraft/SaabJ35F/Model/Liveries");
  print("Liveries init");
  setprop("/instrumentation/g-max", 0);
  use_drop();
  fuel_handler();
  setlistener("/instrumentation/switches/drop_selector/pos", use_drop, 0, 0);
  print("Fuel ... Check");
  g_watch();
  print("G-gauge ... Check");
  gear_watch();
  #landinglight_check();
  print("Gears ... Check");
  light_intens();
  settimer(alt_watch, 3);
  setlistener("/autopilot/enabled", autoOnOff, 0, 0);
  print("Autopilot ... Check");
  init_fr21();
  setlistener("instrumentation/comm/power-btn", fr21_Aonoff, 0, 0);
  setlistener("instrumentation/comm[1]/power-btn", fr21_Bonoff, 0, 0);
  print("Radio ... Check");
 }

#Init Canopy movement
var canopy = aircraft.door.new ("/controls/canopy/", 5);
var canopy_opening = 1 - getprop("/controls/canopy/enabled");
#Prepare covers
var fuel_cover = aircraft.door.new ("/controls/fuel_cover/", 0.4);
var battery_cover = aircraft.door.new ("/controls/battery_cover/", 0.4);
start_up();
