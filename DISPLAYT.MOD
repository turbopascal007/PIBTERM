(*----------------------------------------------------------------------*)
(*              Display_Timers --- Display session timers               *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Timers;

VAR
   Ch: CHAR;
   Y1: INTEGER;
   Y2: INTEGER;
   Y3: INTEGER;
   Y4: INTEGER;

(*----------------------------------------------------------------------*)

PROCEDURE Update_Timers;

BEGIN (* Update_Timers *)

   WriteSXY( TimeString( TimeDiff( Session_Start_Time , TimeOfDay ),
                         Military_Time ),
             58, Y1 + 5, Menu_Text_Color );

   IF Async_Carrier_Detect THEN
      WriteSXY( TimeString( TimeDiff( Dialing_Start_Time , TimeOfDay ),
                            Military_Time ),
                58, Y2 + 5, Menu_Text_Color );

   WriteSXY( TimeString( TimeOfDay , Time_Format ), 25, Y3 + 5,
             Menu_Text_Color );

   WriteSXY( DateString, 25, Y3 + 6, Menu_Text_Color );

END   (* Update_Timers *);

(*----------------------------------------------------------------------*)

BEGIN (* Display_Timers *)

   Draw_Titled_Box( Saved_Screen, 5, 5, 75, 23,
                    'Display session information' );

   TextColor( Menu_Text_Color_2 );

   IF ( Async_Carrier_Detect AND ( Phone_Entry_Number > 0 ) ) THEN
      BEGIN
         WRITE  ('Current host system : ');
         TextColor( Menu_Text_Color );
         WRITELN( Phone_Entry_Data.Phone_Name   );
         TextColor( Menu_Text_Color_2 );
         WRITE  ('Current phone number: ');
         TextColor( Menu_Text_Color );
         WRITELN( LTrim( Phone_Entry_Data.Phone_Number ) );
      END
   ELSE
      BEGIN
         WRITE  ('Current host system :  ');
         TextColor( Menu_Text_Color );
         WRITELN('*** None ***');
         TextColor( Menu_Text_Color_2 );
         WRITE  ('Current phone number:  ');
         TextColor( Menu_Text_Color );
         WRITELN('*** None ***');
      END;

   WRITELN;

   TextColor( Menu_Text_Color_2 );

   WRITE('Elapsed time since PibTerm started      : ');

   Y1 := WhereY;
   WRITELN;

   IF Async_Carrier_Detect THEN
      BEGIN
         WRITE('Elapsed time since current session began: ');
         Y2 := WhereY;
      END
   ELSE
      WRITELN;

   WRITELN;

   WRITE  ('Available heap space in bytes: ');

   TextColor( Menu_Text_Color );
   WRITELN( MaxAvail );

   TextColor( Menu_Text_Color_2 );

   WRITELN;
   WRITE('Current time: ');
   Y3 := WhereY;
   WRITELN;
   WRITELN('Current date: ');

   Update_Timers;

   TextColor( Menu_Text_Color_2 );

   WRITELN;
   WRITE('Current capture file name: ');

   TextColor( Menu_Text_Color );

   IF Capture_On THEN
      WRITELN( Capture_File_Name )
   ELSE
      WRITELN('*** None ***');

   TextColor( Menu_Text_Color_2 );

   WRITE('Current script name      : ');

   TextColor( Menu_Text_Color );

   IF ( Script_File_Mode AND ( Current_Script_Num > 0 ) ) THEN
      WRITELN( Scripts[Current_Script_Num].Script_Name )
   ELSE
      WRITELN('*** None ***');

   TextColor( Menu_Text_Color_2 );

   WRITELN;
   WRITE  ('Enter C to clear dialing session timer, hit ESC to continue ... ');

   WHILE ( NOT PibTerm_KeyPressed ) DO
      BEGIN
         Update_Timers;
         GiveAwayTime( 1 );
      END;

   Read_Kbd( Ch );

   IF ( ORD( Ch ) = ESC ) AND PibTerm_KeyPressed THEN
      Read_Kbd( Ch )
   ELSE
      BEGIN
         IF UpCase( Ch ) = 'C' THEN
            BEGIN
               Dialing_Start_Time := TimeOfDay;
               Write_Log('Dialing session timer reset.', FALSE, FALSE);
            END;
      END;

   Restore_Screen_And_Colors( Saved_Screen );

END   (* Display_Timers *);
