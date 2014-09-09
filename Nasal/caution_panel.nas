# Caution panel Canvas

#Caution class
var Caution = {
  new : func(txt, prp, on, clr, mstr) {
    var m = {parents:[Caution] };
    m.text=txt;
    m.prop=prp;
    m.on=on;
    m.colour=clr;
    m.master=mstr;
    return m;
  }
};

#Caution panel class
var Caution_panel = {
  new: func()
  {
    print("Init caution panel");
    var m = { parents: [Caution_panel] };
    # List cautions
    m.ct=[
      Caution.new("BRAND\nMOTOR", "engines/engine[0]/faults/fire", 1, [1, 0, 0], 1), #TODO
      Caution.new("BRAND\nMOTOR", "engines/engine[0]/faults/fire", 1, [1, 0, 0], 1), #TODO
      Caution.new("BRAND\nEBK P", "engines/engine[0]/faults/ebkfire", 1, [1, 0, 0], 1), #TODO
      Caution.new("STYR\nAUT", "autopilot/on", 0, [1, 0.8, 0], 1),
      Caution.new("MOTOR\nIS", "controls/anti-ice/engine/inlet-heat", 1, [0, 1, 0], 0),
      Caution.new("TANK\nLUFT", "consumables/fuel/pressure-fail", 1, [1, 0.8, 0], 1),
      Caution.new("TANK\nPUMP", "controls/electric/engine[0]/generator", 0, [1, 0.8, 0], 1),
      Caution.new("OLJE\nTRYCK", "controls/engines/engine[0]/faults/oil-pressure-status", 1, [1, 0.8, 0], 1),
      Caution.new("EBK", "engines/engine[0]/RAT", 1, [1, 0.8, 0], 0),
      Caution.new("SYR\nGAS", "controls/pilot/oxygen/", 1, [1, 0.8, 0], 1), #TODO
      Caution.new("EL\nFEL", "controls/electric/engine[0]/generator", 0, [1, 0.8, 0], 1), #TODO
      Caution.new("HYDR\nI", "instrumentation/hydraulic/hydI-fail", 1, [1, 0.8, 0], 1), #TODO
      Caution.new("HYDR\nII", "instrumentation/hydraulic/hydII-fail", 1, [1, 0.8, 0], 1), #TODO
      Caution.new("KABIN\nTRYCK", "controls/pressurization/dump", 1, [1, 0.8, 0], 1), #TODO
      Caution.new("HUV\nLAS", "controls/canopy/enabled", 1, [1, 0.8, 0], 1)];
    # create a new canvas...
    m.canvas = canvas.new({
      "name": "CAUTIONS",
      "size": [512, 512],
      "view": [512, 512],
      "mipmapping": 1
    });
    
    # ... and place it on the object called Caution
    m.canvas.addPlacement({"node": "Caution"});
    m.canvas.setColorBackground(0.1,0.1,0.1);
    var g = m.canvas.createGroup();
    var g_tf = g.createTransform();

    m.cb=[];
    m.ctxt=[];
    var r=0;
    var k=0;
    var w=94;
    var off=8;
    var rx=5;
    var ry=12;
    var lw=6;
    var d=w+off;
    var dt=int(w/2);
    forindex(i; m.ct) {
      append(m.cb, g.createChild("path")
                    .moveTo(k*d+rx, r*d+ry)
                    .lineTo(k*d+w+rx, r*d+ry)
                    .lineTo(k*d+w+rx, r*d+w+ry)
                    .lineTo(k*d+rx, r*d+w+ry)
                    .close()
                    .setStrokeLineWidth(lw)
                    .setColor(m.ct[i].colour[0],m.ct[i].colour[1],m.ct[i].colour[2], 1.0)
                    .setColorFill(m.ct[i].colour[0],m.ct[i].colour[1],m.ct[i].colour[2], 0.3) );

      append(m.ctxt, g.createChild("text")
                      .setAlignment("center-center")
                      .setText(m.ct[i].text)
                      .setFont("condensed.txf")
                      .setFontSize(28, 1.4)
                      .setColor(m.ct[i].colour[0],m.ct[i].colour[1],m.ct[i].colour[2], 1.0)
                      .setTranslation(k*d+dt+rx, r*d+dt+ry));
      k=k+1;
      if (k>4) {
        k=0;
        r=r+1;
      }  
    }

    return m;
  },

  update: func() {
    #Nozzle motor and RAT
    var n1=getprop("engines/engine[0]/n1") or 0;
    var nozzle=getprop("engines/engine[0]/nozzle-pos-norm") or 0;
    var wow=getprop("/gear/gear[0]/wow") or 0;
    if (n1 >=30 and n1<55 and wow == 1) 
      setprop("engines/engine[0]/RAT", 1);
    else if (nozzle < 1 and nozzle > 1.01 - (n1-30)/70) setprop("engines/engine[0]/RAT", 1);
    else setprop("engines/engine[0]/RAT", 0);
    # Oil pressure
    var op=getprop("engines/engine[0]/oil-pressure-psi") or 0;
    if (op < 30) setprop("controls/engines/engine[0]/faults/oil-pressure-status", 1);
    else setprop("controls/engines/engine[0]/faults/oil-pressure-status", 0);
    #Hydr I, II
    if ((getprop("fdm/jsbsim/systems/hydraulic/hydI-sys-p")or 0)<800) 
      setprop("instrumentation/hydraulic/hydI-fail",1);
    else setprop("instrumentation/hydraulic/hydI-fail",0);
    if ((getprop("fdm/jsbsim/systems/hydraulic/hydII-sys-p")or 0)<2150) 
      setprop("instrumentation/hydraulic/hydII-fail",1);
    else setprop("instrumentation/hydraulic/hydII-fail",0);
    var master=0;
    forindex(i; me.ct) {
      var k=0.1;
      if ((getprop("systems/electrical/outputs/battery") or 0) > 20 and getprop(me.ct[i].prop) == me.ct[i].on) {
        k=1;
        if (me.ct[i].master == 1 and master == 0) {
          setprop("/instrumentation/master_alarm/on", 1-getprop("/instrumentation/master_alarm/on"));
          master=1;
        }
      }
      me.cb[i].setColor(me.ct[i].colour[0],me.ct[i].colour[1],me.ct[i].colour[2], k);
      me.cb[i].setColorFill(me.ct[i].colour[0],me.ct[i].colour[1],me.ct[i].colour[2], 0.3*k);
      me.ctxt[i].setColor(me.ct[i].colour[0],me.ct[i].colour[1],me.ct[i].colour[2], k);
    }
    if (master == 0) setprop("/instrumentation/master_alarm/on",0);
    settimer(func me.update(), 0.5)
  },
};

setlistener("/nasal/canvas/loaded", func {
  var panel = Caution_panel.new();
  panel.update();
  print("Caution Panel ... on");
}, 1);

