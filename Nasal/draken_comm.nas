# draken_comm.nas
 var frqAK=[];
 var frq15=[];
 var btnsAK="ABCDEFGHIJK";

 var set_frq = func(f, unit) {
   if (unit=="A" and getprop("instrumentation/comm/power-btn") == 1) {
     setprop("/instrumentation/comm/frequencies/selected-mhz", f);
     setprop("/instrumentation/fr21/frequency_A", f);
   }
   if (unit=="B" and getprop("instrumentation/comm[1]/power-btn") == 1) {
     setprop("/instrumentation/comm[1]/frequencies/selected-mhz", f);
     setprop("/instrumentation/fr21/frequency_B", f);
   }
 }

 var button_handlerAK = func(btn) {
   for (var i=0; i<11; i=i+1) {
     setprop("/instrumentation/fr21/buttons/"~substr(btnsAK, i, 1), 0);
   }
   setprop("/instrumentation/fr21/buttons/Uslash", 0);
   setprop("/instrumentation/fr21/buttons/"~btn, 1);
   if (btn=="Uslash") { set_frq(getprop("/instrumentation/fr21/frequency_A_man"), "A"); }
   else { set_frq(frqAK[find(btn, btnsAK)], "A"); }
 }

 var button_handler15 = func(btn) {
   for (var i=1; i<6; i=i+1) {
     setprop("/instrumentation/fr21/buttons/b"~i, 0);
   }
   setprop("/instrumentation/fr21/buttons/Lslash", 0);
   setprop("/instrumentation/fr21/buttons/"~btn, 1);
   if (btn=="Lslash") { set_frq(getprop("/instrumentation/fr21/frequency_B_man"), "B"); }
   else { set_frq(frq15[num(btn[1])-48], "B") }
 }


 var manual_handler = func(unit) {
   if (unit == "A" and getprop("instrumentation/fr21/buttons/Uslash") == 1) {
     set_frq(getprop("instrumentation/fr21/frequency_A_man"), "A"); 
   }
   if (unit == "B" and getprop("instrumentation/fr21/buttons/Lslash") == 1) {
     set_frq(getprop("instrumentation/fr21/frequency_B_man"), "B"); 
   }
 }

 var init_fr21 = func {
   append(frqAK, getprop("/instrumentation/comm[0]/frequencies/selected-mhz") or 0);
   append(frq15, getprop("/instrumentation/comm[1]/frequencies/selected-mhz") or 0);
   append(frqAK, getprop("/instrumentation/comm[0]/frequencies/standby-mhz") or 0);
   append(frq15, getprop("/instrumentation/comm[1]/frequencies/standby-mhz") or 0);
   var fh = io.open(getprop("/sim/aircraft-dir")~"/Fr21.txt", "r");
   var line="";
   var n=0;
   print("Reading radio frequencies");
   while (line != nil) {
     line = io.readln(fh);
     if (line != nil) {
       var c_arr=split(",", line);
       if (size(c_arr) > 1) {
         if (n<9) { append(frqAK, num(c_arr[1])); }
         else { append(frq15, num(c_arr[1])); }
         n=n+1;
         print(line);
       }
     }
   }
   print("Done reading radio frequencies");
   io.close(fh);
 }

 var fr21_Aonoff =func(n) {
   var on = n.getValue();
   if (on == 1) {
     for (var i=0; i<11; i=i+1) {
       if (getprop("/instrumentation/fr21/buttons/"~substr(btnsAK, i, 1)) == 1)
         { set_frq(frqAK[i], "A"); }
     }
   }
 }

 var fr21_Bonoff =func(n) {
   var on = n.getValue();
   if (on == 1) {
     for (var i=1; i<6; i=i+1) {
       if (getprop("/instrumentation/fr21/buttons/b"~i) == 1)
         { set_frq(frq15[i], "B");  }
     }
   }
 }

