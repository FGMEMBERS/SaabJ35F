var bombableObject = {
  ########################################################################
  ########################################################################
  # INITIALIZE BOMBABLE
  #
  # Initialize constants and main routines for maintaining altitude
  # relative to ground-level, relocating after file/reset, and
  # creating bombable/shootable objects.
  #
  # These routines are found in FG/nasal/bombable.nas
  #
  ########################################################################
  # INITIALIZE BOMBABLE Object
  # This object will be slurped in the object's node as a child
  # node named "bombable".
  # All distances are specified in meters.
  # All altitudes are relative to current ground level at the object's
  # location

  objectNodeName : nil,
  objectNode : nil,
  updateTime_s : 1/3,
  # time, in seconds, between the updates that keep the object at
  # its AGL. Tradeoff is high-speed updates look more realistic but
  # slow down the framerate/cause jerkiness.  Faster-moving objects
  # will need more frequent updates to look realistic.  update time
  # faster than about 1/3 seems to have a noticeable effect on frame
  # rate

  altitudes : {
    wheelsOnGroundAGL_m : 1,
    # altitude correction to add to your aircraft or ship that is
    # needed to put wheels on ground (or, for a ship, make it float
    # in the water at the correct level).  For most objects this is
    # 0 but some models need a small correction to place them
    # exactly at ground level

    minimumAGL_m : 300,
    # minimum altitude above ground level this object is allowed to fly

    maximumAGL_m : 20000,
    # maximum altitude AGL this object is allowed to fly, ie, operational ceiling

    crashedAGL_m : 0.6,
    # altitude AGL when crashed.  Ships will sink to this level,
    # aircraft or vehicles will sink into the ground as landing gear
    # collapses or tires deflate. Should be negative, even just
    # -0.001.
  },

  velocities : {
    maxSpeedReduce_percent : 0.5,
    # max % to reduce speed, per step, when damaged

    minSpeed_kt : 112,
    # minimum speed to reduce to when damaged.  Ground vehicles and
    # ships might stop completely when damaged but aircraft will need
    # a minimum speed so they keep moving until they hit the ground.

    cruiseSpeed_kt : 450,
    # cruising speed, typical/optimal cruising speed, V C for aircraft

    attackSpeed_kt : 750,
    # typical/optimal speed when aggressively attacking or evading, in
    # level flight for aircraft

    maxSpeed_kt : 756,
    # Maximum possible speed under dive or downhill conditions, V NE for aircraft

    damagedAltitudeChangeMaxRate_meterspersecond : 30,
    # max rate to sink or fly downwards when damaged, in meters/second

    # The terminal velocities are calculated by opening the 'real' AC
    # in FG, level flight, full throttle, then putting
    # the AC at different angles of attack with the autopilot,
    # and noting the terminal airspeed & vertical speed velocities.
    # For best results, do it near sea level, under 5000 feet altitude.
    # One or two each of climb & dive velocities are probably sufficient.
    # However if you do more we may be able to use the more precise
    # data in the future.
    #
    # Note that these are intended to be true airspeed whereas FG's
    # /velocities/airspeed-kt reports indicated airspeed, so some
    # conversion or reference to groundspeed-kt is needed.
    #
    # In FG /velocities/groundspeed-kt is equal (or close
    # to equal, except for wind . . .) true airspeed when pitch=0
    # but as pitch increases or decreases that will change.
    diveTerminalVelocities: {
      point1: { airspeed_kt : 1060, vertical_speed_fps : - 337},
      point2: { airspeed_kt : 1230, vertical_speed_fps : - 755},
    },

    climbTerminalVelocities: {
      point1: { airspeed_kt : 468, vertical_speed_fps : 236},
      point2: { airspeed_kt : 843, vertical_speed_fps : 251},
      #point3: { airspeed_kt : 1100, vertical_speed_fps : 161},
    },

  },

  # The evasion system makes the AI aircraft dodge when they come under fire.
  evasions : {
    dodgeDelayMax_sec : 15,
    # max time to delay/wait between dodges

    dodgeDelayMin_sec : 5,
    # minimum time to delay/wait between dodges

    dodgeMax_deg : 80,
    # Max amount to turn when dodging
    # 90 degrees = instant turn, unrealistic
    # up to 80 is usually OK, somewhere in 80-85 starts to be unrealistically fast
    # >85 is usually very unrealistic.  You must test this in your scenario, however.

    dodgeMin_deg : 75,
    # minimum amount to turn when dodging

    rollRateMax_degpersec : 300,
    # you can figure this out by rolling the corresponding FG aircraft
    # and timing a 180 or 360 deg roll

    dodgeROverLPreference_percent : 50,
    # Preference for right turns vs. left when dodging.  90% means 90%
    # right turns, 50% means 50% right turns.

    dodgeAltMin_m : -8000,
    # Aircraft will begin to move up or down

    dodgeAltMax_m : 8000,
    # Max & Min are relative to current alt

    dodgeVertSpeedClimb_mps : 1500,
    # Max speed to climb when evading

    dodgeVertSpeedDive_mps : 1500,
    # Max speed to dive when evading
  },

  # The attack system makes the AI aircraft turn and fly towards
  # other aircraft
  attacks : {
    maxDistance_m : 30000,
    # max distance to turn & attack main aircraft

    minDistance_m : 4000,
    # min distance to turn & attack main aircraft, ie, fly away this
    # far before turning to attack again

    continueAttackAngle_deg : 80,

    # when within minDistance_m, the aircraft will continue to turn
    # towards the main aircraft and attack *if* if the angle is less
    # than this amount from dead ahead

    altitudeHigherCutoff_m : 30000,
    # will attack the main aircraft unless this amount higher than it or more

    altitudeLowerCutoff_m : 30000,
    # will attack the main aircraft unless this amount lower than it or more

    climbPower : 8000,
    # How powerful the aircraft is when climbing during an attack;
    # 4000 would be typical for, say a Zero--scale accordingly for
    # others; higher is stronger

    divePower : 10000,
    # How powerful the aircraft is when diving during and attack; 6000
    # typical of a Zero--could be much more than climbPower if the
    # aircraft is a weak climber but a strong diver

    rollMin_deg : 75,
    # when turning on attack, roll to this angle min for sedate,
    # Cessna-like manuevers make rollMin low.  If you want an
    # aggressive, attacking, aiming fighter keep it close to rollMax,
    # or even almost equal to rollMax

    rollMax_deg : 78,
    # when turning on attack, roll to this angle max
    # 90 degrees = instant turn, unrealistic
    # up to 80 might be OK, depending on aircraft & speed; somewhere in
    # 80-85 starts to be unrealistically fast
    # >85 is usually very unrealistic.  You must test this in your scenario, however.

    rollRateMax_degpersec : 120,
    # you can figure this out by rolling the corresponding FG aircraft and
    # timing a 180 or 360 deg roll

    attackCheckTime_sec : 10,
    # check for need to attack/correct course this often

    attackCheckTimeEngaged_sec : 0.5,
    # once engaged with enemy, check/update course this frequently
  },

  # The weapons system makes the AI aircraft fire on the main aircraft.
  # You can define any number of weapons -- just enclose each in curly
  # brackets and separate with commas (,).
  weapons: {
    ADEN: {
      #internal name - this can be any name you want; must be a valid nasal variable name
      name : "30 mm ADEN cannon",
      # name presented to users, ie in on-screen messages

      maxDamage_percent : 65,
      # maximum percentage damage one hit from the aircraft's main weapon/machine
      # guns will do to an opponent

      maxDamageDistance_m : 1000,
      # maximum distance at which the aircrafts main weapon/maching guns
      # will be able to damage an opponent

      weaponAngle_deg: { heading: 0, elevation: 0 },
      # direction the aircraft's main weapon is aimed.
      # 0,0 = straight ahead,
      # 90,0=directly right,
      # 0,90=directly up,
      # 0,180=directly back, etc.

      weaponOffset_m: {x:-1.1, y:1.8, z:0.2},
      # Offset of the weapon from the main aircraft center

      weaponSize_m : {start:.1, end:.1},
      # Visual size of the weapon's projectile, in meters, at start & end of its path
    }
  },

  dimensions: {
    width_m :  9.42,
    # width of your object, ie, for aircraft, wingspan

    length_m : 15.35,
    # length of your object, ie, for aircraft, distance nose to tail

    height_m :  3.89,
    # height of your object, ie, for aircraft ground to highest point
    # when sitting on runway

    damageRadius_m : 7.68,
    # typically 1/2 the longest dimension of the object. Hits within this distance of the
    # center of object have some possibility of damage

    vitalDamageRadius_m : 4,
    # typically the radius of the fuselage or cockpit or other most
    # vital area at the center of the object.  Always smaller than
    # damageRadius_m

    crashRadius_m : 6, # It's a crash if the main aircraft hits in this area.
  },

  vulnerabilities : {
    damageVulnerability : 9,
    # Vulnerability to damage from armament, 1=normal M1 tank;
    # higher to make objects easier to kill and lower to make
    # them more difficult.  This is a multiplier, so 5 means
    # 5X easier to kill than an M1, 1/5 means 5X harder to kill.

    engineDamageVulnerability_percent : 6,
    # Chance that a small-caliber machine-gun round will damage
    # the engine.

    fireVulnerability_percent : 50,
    # Vulnerability to catching fire. 100% means even the slightest
    # impact will set it on fire; 20% means quite difficult to set
    # on fire; 0% means set on fire only when completely damaged;
    # -1% means never set on fire.

    fireDamageRate_percentpersecond : .1,
    # Amount of damage to add, per second, when on fire.
    # 100%=completely damaged. Warthog is relatively damage-resistant.

    fireExtinguishMaxTime_seconds : 80,
    # Once a fire starts, for this many seconds there is a chance
    # to put out the fire; fires lasting longer than this won't
    # be put out until the object burns out.

    fireExtinguishSuccess_percentage : 45,
    # Chance of the crew putting out the fire within the MaxTime
    # above. Warthog is relatively damage-resistant.

    explosiveMass_kg : 32000,
    # mass of the object in KG, but give at least a 2-10X bonus
    # to anything carrying flammables or high explosives.

    redout: { enabled: 1 }
  },

  #########################################
  # LIVERY DEFINITIONS
  #
  # Path to livery files to use at different damage levels.
  # Path is relative to the AI aircraft's directory.
  # The object will start with the first livery listed and
  # change to succeeding liveries as the damage
  # level increases. The final livery should indicate full damage/
  # object destroyed.
  #
  # If you don't want to specify any special liveries simply set
  # damageLivery : nil and the object's normal livery will be used.
  damageLiveries : {
    damageLivery : [  ]
  },
};

load = func (thisNode) {
  var thisNodeName = thisNode.getPath();
  print("Saab 35: loading bombable support ", thisNodeName);

  if (getprop ("/bombable/menusettings/bombable-enabled") != 1) {
    print ("Bombable not installed or not loaded");
    return;
  }
  if ( bombable.check_overall_initialized (thisNodeName) ) {
    print ("Bombable support already initialized");
    return;
  }

  bombableObject.objectNodeName = thisNodeName;
  bombableObject.objectNode     = thisNode;
  bombable.initialize ( bombableObject );

  # LOCATION: Relocate object to maintain its position after file/reset
  # (best not used for airplanes)
  # bombable.location_init ( thisNodeName );
  #
  # GROUND: Keep object at altitude relative to ground level
  bombable.ground_init ( thisNodeName );

  # ATTACK: Make the object attack the main aircraft
  bombable.attack_init ( thisNodeName );

  # WEAPONS: Make the object shoot the main aircraft
  bombable.weapons_init ( thisNodeName );

  # BOMBABLE: Make the object bombable/damageable
  bombable.bombable_init ( thisNodeName );

  # SMOKE/CONTRAIL: Start a flare, contrail, smoke trail, or exhaust
  # trail for the object.
  # Smoke types available: flare, jetcontrail, pistonexhaust, smoketrail,
  # damagedengine
  bombable.startSmoke("jetcontrail", thisNodeName );
}

var unload = func (thisNode) {
  print("Saab 35: unloading bombable support.");
  var nodeName = thisNode.getPath();
  bombable.de_overall_initialize( nodeName );
  bombable.initialize_del( nodeName );
  bombable.ground_del( nodeName );
  bombable.location_del (nodeName);
  bombable.bombable_del( nodeName );
  bombable.attack_del( nodeName );
  bombable.weapons_del (nodeName);
}

# load() and unload() are executed only when the Saab 35 is an AI or MP
# aircraft.  When the Saab 35 is the main aircraft and bombable is
# enabled we also want to advertize our vulnerabilities and weapons,
# like so:
setlistener ("/bombable/menusettings/bombable-enabled", func (enabled) {
  if (!enabled.getValue()) return;
  bombable.debprint ("Saab 35: Loading main aircraft vulnerabilities and weapons");
  bombable.setAttributes (bombableObject);
}, 1);
