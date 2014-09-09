#Nav settings and beacons
#Modes:
# 0=Fran, 1=Forv., 2=Stril, 3=Strid, 4=NAVRIKTN(NDB)
# 5=Nav 400 (VOR 400 km), 6=Nav 40 (VOR 40 km)
# 7=Landn 40 (VOR 40 km, appr.), 8=Barbro (ILS)
var letters=["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P"];
var nav_dir="";
var nav_dis="";
var nav_gsa="";
var nav_gsd="";

var beacon = { code: "", type: "", frq: 0, note: ""};
var new_beacon = func(bv) {
  var b = {parents:[beacon] };
  b.code=bv[0];
  b.type=bv[1];
  b.frq=num(bv[2]);
  b.note=bv[3];
  return b;
}

var beacons = [];
var active=-1;

var read_beacons = func {
  print("Reading beacons");
  var fh = io.open(getprop("/sim/aircraft-dir")~"/beacons.txt", "r");
  var b="";
  while (b != nil) {
    b = io.readln(fh);
    if (b != nil) {
      append(beacons, new_beacon(split(",", b)));
      print("Adding: "~b);
    }
  }
  io.close(fh); 
}

var set_beacon = func {
  var md=getprop("/instrumentation/navradio/mode");
  if (md<4) return;
  active=-1;
  if (md<8) {
    var cd=letters[getprop("/instrumentation/navradio/anita1")]~
            letters[getprop("/instrumentation/navradio/anita2")];
    forindex (i; beacons) {
      if (substr(beacons[i].code,0,2) == cd) {
        print("Selecting "~beacons[i].code);
        active=i;
        break;
      }
    }
    #VOR
    if (beacons[i].type =="VOR") {
      setprop("/instrumentation/nav/frequencies/selected-mhz", beacons[i].frq);
      nav_dir="/instrumentation/nav/radials/reciprocal-radial-deg";
      nav_dis="/instrumentation/nav/nav-distance";
      nav_gsa="";
      nav_gsd="";
    #NDB
    } else if (beacons[i].type =="NDB") {
      setprop("/instrumentation/adf/frequencies/selected-khz", beacons[i].frq);
      nav_dir="/instrumentation/adf/indicated-bearing-deg";
      setprop("/instrumentation/navradio/dis", 0);
      nav_dis="";
      nav_gsa="";
      nav_gsd="";
    }      
  } else {
    #ILS
    var cd=letters[getprop("/instrumentation/navradio/anita1")]~
            letters[getprop("/instrumentation/navradio/anita2")]~
            letters[getprop("/instrumentation/navradio/barbro")];
    forindex (i; beacons) {
      if (beacons[i].code == cd and beacons[i].type =="ILS") {
        print("Selecting "~beacons[i].code);
        active=i;
        setprop("/instrumentation/nav/frequencies/selected-mhz", beacons[i].frq);
        nav_dir="/instrumentation/nav/radials/reciprocal-radial-deg";
        nav_dis="/instrumentation/nav/nav-distance";
        nav_gsa="/instrumentation/nav/gs-needle-deflection-norm";
        nav_gsd="/instrumentation/nav/heading-needle-deflection-norm";
        break;
      }
    }  
  }
  if (active==-1) {
    print("No beacon found");
    nav_dir="";
    nav_dis="";
    nav_gsa="";
    nav_gsd="";
  } else screen.log.write("Selected "~beacons[i].note);  
}

var set_nav_mode = func {
  var md=getprop("/instrumentation/navradio/mode");
  if (md != 2) setprop("autopilot/route-manager/active", 0);
  if (md==0) {
    nav_dir="/instrumentation/heading-indicator/heading-bug-deg";
    nav_dis="";
    nav_gsa="";
    nav_gsd="";
    setprop("instrumentation/radar/mode", 0);
    SaabJ35F.set_AHK_mode(0);
  } else if (md==1) {
    nav_dir="/instrumentation/heading-indicator/heading-bug-deg";
    nav_dis="";
    nav_gsa="";
    nav_gsd="";
    setprop("instrumentation/radar/mode", 0);
    SaabJ35F.set_AHK_mode(1);  
  } else if (md==2) {
    setprop("autopilot/route-manager/active", 1);
    nav_dir="autopilot/route-manager/wp[0]/bearing-deg";
    nav_dis="autopilot/route-manager/wp[0]/dist";
    nav_gsa="";
    nav_gsd="";
    setprop("instrumentation/radar/mode", 1);
    SaabJ35F.set_AHK_mode(5);  
  } else if (md==3) {
    nav_dir="/instrumentation/heading-indicator/heading-bug-deg";
    nav_dis="";
    nav_gsa="";
    nav_gsd="";
    setprop("instrumentation/radar/mode", 1);
    SaabJ35F.set_AHK_mode(1);  
  } else if (md==4) {
    set_beacon();
    setprop("instrumentation/radar/mode", 5);
    SaabJ35F.set_AHK_mode(1);  
  } else if (md==5) {
    setprop("instrumentation/radar/mode", 5);
    set_beacon();
    SaabJ35F.set_AHK_mode(4);  
  } else if (md==6) {
    set_beacon();
    setprop("instrumentation/radar/mode", 5);
    SaabJ35F.set_AHK_mode(3);  
  } else if (md==7) {
    set_beacon();
    setprop("instrumentation/radar/mode", 5);
    SaabJ35F.set_AHK_mode(2);  
  } else if (md==8) {
    set_beacon();
    setprop("instrumentation/radar/mode", 6);
    SaabJ35F.set_AHK_mode(6);  
  }
}

var update_nav= func {
  var md=getprop("/instrumentation/navradio/mode");
  if ((getprop("systems/electrical/outputs/inst_ac") or 0) == 0) {
    setprop("/instrumentation/navradio/dir", 0);
    setprop("/instrumentation/navradio/dis", 0);
    setprop("/instrumentation/navradio/gs_alt", 0);
    setprop("/instrumentation/navradio/gs_dir", 0);
  } else {
    if (nav_dir != "") {
      #ADF gives bearing relative to aircraft the others compass-bearing
      if (beacons[active].type=="NDB" and md > 3) {
        var d=getprop(nav_dir) or 0;
        if (d>180) d=d-360;
        d=d+getprop("instrumentation/heading-indicator/indicated-heading-deg");
        if (d<0) d=d+360;
        else if (d>360) d=d-360;
        setprop("/instrumentation/navradio/dir", d);
      } else setprop("/instrumentation/navradio/dir", getprop(nav_dir) or 0);
    }
    if (nav_dis != "") setprop("/instrumentation/navradio/dis", getprop(nav_dis) or 0);
    if (nav_gsa != "") setprop("/instrumentation/navradio/gs_alt", getprop(nav_gsa) or 0);
    if (nav_gsd != "") setprop("/instrumentation/navradio/gs_dir", getprop(nav_gsd) or 0);
  }
  settimer(update_nav, 0.1);
}

#Start
read_beacons();
set_nav_mode();
update_nav();
