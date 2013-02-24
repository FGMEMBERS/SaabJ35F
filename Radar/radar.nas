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
    m.stroke_dir=0;
    m.no_stroke = 6;
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
     }

    m.antennay=g.createChild("path")
                .moveTo(900, 512)
                .lineTo(920, 512)
                .close()
                .setStrokeLineWidth(18)
                .setColor(0.6,0.7,1.0, 1.0);
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
    if (rmode > 0 and rmode < 5) {
      if (me.oldmode == 0) {
        me.oldmode=rmode;
        for(var i=1; i < me.no_stroke; i = i+1) me.stroke[i].show();
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
      var pos=me.stroke_dir+
          3*me.stroke_mode*math.sin(getprop("sim/time/elapsed-sec")*60/me.stroke_mode);
      for(var i=1; i < me.no_stroke; i = i+1) {
        me.stroke_pos[i-1]=me.stroke_pos[i];
        me.tfstroke[i-1].setTranslation(me.stroke_pos[i-1], 0);
      }
      me.stroke_pos[me.no_stroke-1] = pos;
      me.tfstroke[me.no_stroke-1].setTranslation(pos, 0);

      #Antenna pitch
      if (rmode == 1)
        me.antenna_pitch=30.0*math.sin(getprop("sim/time/elapsed-sec")/6.28);
      else if (rmode==2)
        me.antenna_pitch=getprop("instrumentation/radar/antenna_pitch");
      me.tfantennay.setTranslation(0, 
         -5.06*me.antenna_pitch);
    } else {
    #Off
      if (me.oldmode !=0) {
        me.oldmode=rmode;
        for(var i=1; i < me.no_stroke; i = i+1) me.stroke[i].hide();
        me.antennay.hide();
      }
    }

    #Guide animation
    if (rmode < 5) {
        me.glide_target=480;
        me.course_target=480;
    } else if (rmode == 5) {
        me.glide_target=480;
        me.course_target=0;
    } else if (rmode == 6) {
        me.glide_target=0;
        me.course_target=0;
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
};

setlistener("/nasal/canvas/loaded", func {
  var scope = radar.new();
  scope.update();
}, 1);
