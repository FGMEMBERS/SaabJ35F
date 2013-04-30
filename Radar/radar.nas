# ==============================================================================
# Radar
# ==============================================================================

var abs = func(n) { n < 0 ? -n : n }
var sgn = func(n) { n < 0 ? -1 : 1 }

var radar = {
  new: func()
  {
    print("Powering up radar...");

    var m = { parents: [radar] };
    
    # create a new canvas...
    m.canvas = canvas.new({
      "name": "RADAR",
      "size": [1024, 1024],
      "view": [1024, 1024],
      "mipmapping": 1
    });
    
    # ... and place it on the object called Screen
    m.canvas.addPlacement({"node": "Screen"});
    m.canvas.setColorBackground(0.20,0.27,0.16);
    var g = m.canvas.createGroup();
    var g_tf = g.createTransform();

    m.oldmode=0;
    m.glide_pos=1000; #Actual position
    m.course_pos=1000; #Actual position
    m.glide_target=1000; #Target position
    m.course_target=1000; #Target position
    m.stroke_mode=120;
    m.antenna_pitch=0;
    m.stroke_dir=0; #center yaw -80 to 80 mode=2
    m.no_stroke = 6;
    m.no_blip=10;
    m.stroke_pos= [];
    for(var i=0; i < m.no_stroke; i = i+1) {
      append(m.stroke_pos, 0);
    }

    m.stroke = [];
    m.tfstroke=[];
    for(var i=0; i < m.no_stroke; i = i+1) {
        append(m.stroke,
         g.createChild("path")
         .moveTo(512, 120)
         .lineTo(512, 904)
         .close()
         .setStrokeLineWidth(12)
         .setColor(0.6,0.7,1.0, 1.0/(m.no_stroke-i)));
       append(m.tfstroke, m.stroke[i].createTransform());
       m.tfstroke[i].setTranslation(0, 0);
       m.stroke[i].hide();
     }

    m.blip = [];
    m.blip_alpha=[];
    m.tfblip=[];
    for(var i=0; i < m.no_blip; i = i+1) {
        append(m.blip,
         g.createChild("path")
         .moveTo(502, 860)
         .lineTo(522, 860)
         .close()
         .setStrokeLineWidth(12)
         .setColor(0.6,0.7,1.0, 1.0));
       append(m.tfblip, m.blip[i].createTransform());
       m.tfblip[i].setTranslation(0, 0);
       m.blip[i].hide();
       append(m.blip_alpha, 1);
     }
     
    m.antennay=g.createChild("path")
                .moveTo(900, 512)
                .lineTo(920, 512)
                .close()
                .setStrokeLineWidth(18)
                .setColor(0.6,0.7,1.0, 1.0);
    m.antennay.hide();
    m.tfantennay=m.antennay.createTransform();

    m.glide=g.createChild("path")
                .moveTo(10, 512)
                .lineTo(1000, 512)
                .close()
                .setStrokeLineWidth(18)
                .setColor(0.96,0.74,0.20, 1.0);
    m.tfglide=m.glide.createTransform();
    m.tfglide.setTranslation(0, 500);

    m.course=g.createChild("path")
                .moveTo(512, 10)
                .lineTo(512, 1000)
                .close()
                .setStrokeLineWidth(18)
                .setColor(0.96,0.74,0.20, 1.0);
    m.tfcourse=m.course.createTransform();
    m.tfcourse.setTranslation(500, 0);

    m.scale=g.createChild("image")
             .setFile("Radar/scale.png")
             .setSourceRect(0,0,1,1)
             .setSize(1024,1024)
             .setTranslation(0,0);

    return m;
  },

  update: func()
  {
  #Modes 0=Off, 1=Autoscan, 2=Manual, 5=Course guide, 6=Course and glide
    var rmode=getprop("instrumentation/radar/mode");
    if ((getprop("systems/electrical/outputs/inst_ac") or 0) == 0) rmode=0;
    if (rmode > 0 and rmode < 5) {
      if (me.oldmode == 0 or me.oldmode > 4) {
        me.oldmode=rmode;
        forindex (i; me.stroke) me.stroke[i].show();
        me.antennay.show();
      }
      if (rmode ==1) {
        me.stroke_mode=120;
        me.stroke_dir=0;
      } else if (rmode==2) {
        me.stroke_mode=getprop("instrumentation/radar/scan_mode");
        if (me.stroke_mode == 40) 
          me.stroke_dir=getprop("instrumentation/radar/antenna_yaw")
        else me.stroke_dir=0;
      }
      #Stroke animation
      var pos=6*me.stroke_dir+
          3*me.stroke_mode*math.sin(getprop("sim/time/elapsed-sec")*60/me.stroke_mode);
      for(var i=1; i < me.no_stroke; i = i+1) {
        me.stroke_pos[i-1]=me.stroke_pos[i];
        me.tfstroke[i-1].setTranslation(me.stroke_pos[i-1], 0);
      }
      me.stroke_pos[me.no_stroke-1] = pos;
      me.tfstroke[me.no_stroke-1].setTranslation(pos, 0);

      #Antenna pitch
      if (rmode == 1)
        me.antenna_pitch=30.0*math.sin(getprop("sim/time/elapsed-sec")*2);
      else if (rmode==2)
        me.antenna_pitch=getprop("instrumentation/radar/antenna_pitch");
      me.tfantennay.setTranslation(0, 
         -5.06*me.antenna_pitch);
         
      #Uppdaterar blips
      me.update_blip(rmode);
    } else {
    #Off
      if (me.oldmode !=0 and me.oldmode < 5) {
        me.oldmode=rmode;
        forindex (i; me.stroke) me.stroke[i].hide();
        forindex (i; me.blip) me.blip[i].hide();
        me.antennay.hide();
      }
    }

    #Guide animation
    #TODO mode 6,5
    if (rmode < 5) {
        me.glide_target=480;
        me.course_target=480;
    } else if (rmode == 5) {
        me.glide_target=480;
        me.course_target=
          calc_c_target(getprop("instrumentation/heading-indicator/indicated-heading-deg"),
                        getprop("/instrumentation/navradio/dir"));
    } else if (rmode == 6) {
        me.glide_target=getprop("/instrumentation/navradio/gs_alt")*430;
        me.course_target=getprop("/instrumentation/navradio/gs_dir")*430;
    }
    var gm=me.glide_target-me.glide_pos;
    var cm=me.course_target-me.course_pos;
    if (abs(gm) > 36) gm=36*sgn(gm);
    me.glide_pos=me.glide_pos+gm;
    if (abs(cm) > 36) cm=36*sgn(cm);
    me.course_pos=me.course_pos+cm;
    me.tfglide.setTranslation(0, me.glide_pos);
    me.tfcourse.setTranslation(me.course_pos, 0);
    settimer(func me.update(), 0.05);
  },
  
  update_blip: func(rmode) {
        var self = geo.aircraft_position();
        var pitch=getprop("orientation/pitch-deg")*0.0174533;
        var roll=-getprop("orientation/roll-deg")*0.0174533;
        var alt0=getprop("position/altitude-ft")*0.305;
        var dir=getprop("orientation/heading-deg");
        var b_i=0;
        foreach (var mp; multiplayer.model.list) {
            var n = mp.node;
            var x = n.getNode("position/global-x").getValue();
            var y = n.getNode("position/global-y").getValue();
            var z = n.getNode("position/global-z").getValue();
            var ac = geo.Coord.new().set_xyz(x, y, z);
            var distance = nil;
            call(func distance = self.distance_to(ac), nil, var err = []);
            if ((size(err))or(distance==nil)) {
                # Oops, have errors. Bogus position data (and distance==nil).
                    print("Received invalid position data: " ~ debug._error(mp.callsign));
            }
            else
            {
                # Node with valid position data (and "distance!=nil").
                var alt=n.getNode("position/altitude-ft").getValue()*0.305;
                var yg_rad=math.atan2((alt-alt0), distance)-pitch;
                var xg_rad=(self.course_to(ac)-dir)*0.0174533;
                if (xg_rad > math.pi) xg_rad=xg_rad-2*math.pi;
                var ya_rad=xg_rad*math.sin(roll)+yg_rad*math.cos(roll);
                var xa_rad=xg_rad*math.cos(roll)-yg_rad*math.sin(roll);
                if (b_i < me.no_blip and distance < 40000 and alt-100 > getprop("/environment/ground-elevation-m")){
                  if (ya_rad > -0.5 and ya_rad < 0.5 and xa_rad > -1 and xa_rad < 1) {
                      if (abs(xa_rad*430-me.stroke_pos[me.no_stroke-1]) < 30) {
                        if (rmode==2) me.blip_alpha[b_i]=1-abs(me.antenna_pitch*0.01745-ya_rad);
                        else me.blip_alpha[b_i]=1;
                        me.tfblip[b_i].setTranslation(xa_rad*430, -distance*0.0174); 
                      } else me.blip_alpha[b_i] = me.blip_alpha[b_i]*0.98;
                      me.blip[b_i].show();
                      me.blip[b_i].setColor(0.6,0.7,1.0, me.blip_alpha[b_i]);
                      b_i=b_i+1;
                  }
                }
            }
        }
        for (i = b_i; i < me.no_blip; i=i+1) me.blip[i].hide();
    },
};

var calc_c_target= func(crs, trg) {
  var diff=trg-crs;
  if (diff>180) diff=diff-360;
  if (diff<-180) diff=360+diff;
  diff=7.1667*diff;
  if (diff > 430) diff=430;
  else if (diff < -430) diff=-430;
  return diff;
}

setlistener("/nasal/canvas/loaded", func {
  var scope = radar.new();
  scope.update();
}, 1);
