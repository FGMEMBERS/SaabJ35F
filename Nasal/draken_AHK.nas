#AHK functions

#Modes: NOLLA=0, HOJDANDR=1, LANDA=2

#Running mean vectors
var dv = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
var av = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];

#Conversion table AS to GS
var factor = 
[ [-1000, 1],
  [0, 1],
  [5000, 1.11],
  [10000, 1.21],
  [15000, 1.29],
  [20000, 1.41],
  [25000, 1.54],
  [30000, 1.72],
  [36000, 2.00],
  [40000, 2.22],
  [50000, 2.86],
  [60000, 3.63],
  [70000, 4.44],
  [100000, 13]];

#Damped setting of distance needle
var set_dist = func(x, k) {
  var m=0;
  for (var i=1; i < 16; i = i+1) {
    dv[i-1]=dv[i];
      m=m+dv[i];
    }
    dv[15]=x*k;
    return (m+x*k)/16;
}

#Damped setting of target needle
var set_alt = func(x, k) {
  var m=0;
  for (var i=1; i < 16; i = i+1) {
    av[i-1]=av[i];
      m=m+av[i];
    }
    av[15]=x*k;
    return (m+x*k)/16;
}

#Calculating groundspeed from ias
var calc_gs = func(h, asp) {
  for (var i=1; i < 12; i = i+1) if (h<factor[i][0]) break;
  var y=(h-factor[i-1][0])/(factor[i][0]-factor[i-1][0]);
  return asp*(y*(factor[i][1]-factor[i-1][1])+factor[i-1][1]);
}

#HOJDANDRING
var mode_dh = func {
  var h=getprop("/instrumentation/altimeter/pressure-alt-ft");
  var dhdt=getprop("/instrumentation/vertical-speed-indicator/indicated-speed-fpm")*0.305;
  var gs=calc_gs(h, getprop("/instrumentation/airspeed-indicator/indicated-speed-kt")*1.852);
  setprop("/instrumentation/AHK/needle_target", set_alt(dhdt+h*0.305, 0.00005));
  if (dhdt != 0 and gs > 100) {
    var t = 1000/dhdt;
    var s2 = gs*gs/3600*t*t;
    if (s2 > 1) var d= math.sqrt(s2-1); else d=0;
      setprop("/instrumentation/AHK/needle_dist", set_dist(d, 0.025));
  }
  if (getprop("/instrumentation/AHK/mode") == 1) settimer(mode_dh, 0.0625);
}

#LANDA
var mode_landa = func {
  var h=getprop("/instrumentation/altimeter/pressure-alt-ft");
  var dhdt=getprop("/instrumentation/vertical-speed-indicator/indicated-speed-fpm");
  var gs=calc_gs(h, getprop("/instrumentation/airspeed-indicator/indicated-speed-kt")*1.852);
  setprop("/instrumentation/AHK/needle_target", set_alt(dhdt+h, 0.000152509));
  if (dhdt != 0 and gs > 100) {
    var t = h/dhdt;
    var s2 = gs*gs/3600*t*t;
    if (s2 > 1) var d= math.sqrt(s2-1); else d=0;
      setprop("/instrumentation/AHK/needle_dist", set_dist(d, 0.025));
  }
  if (getprop("/instrumentation/AHK/mode") == 2) settimer(mode_landa, 0.0625);
}

#NOLLA
var mode_nolla=func {
  setprop("/instrumentation/AHK/needle_target", set_alt(0, 1));
  setprop("/instrumentation/AHK/needle_dist", set_dist(0, 1));
  if (getprop("/instrumentation/AHK/mode") == 0 and 
  (getprop("/instrumentation/AHK/needle_dist") != 0  or  
  getprop("/instrumentation/AHK/needle_target") != 0)) settimer(mode_nolla, 0.0625);
}

#Setting modes
var set_mode = func {
  var ms = getprop("/instrumentation/AHK/mode");
  if (ms==0) {
    print("AHK mode NOLLA");
    mode_nolla();
  } else if (ms==1) {
    print("AHK mode HOJDANDR");
    mode_dh();
  } else if (ms==2) {
    print("AHK mode LANDA");
    mode_landa();
  }
}

