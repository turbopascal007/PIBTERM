(*--------------------------------------------------------------------------*)
(*        Emulate_Gossip --- Gossip Mode from PibTerm to PibTerm            *)
(*--------------------------------------------------------------------------*)

PROCEDURE Emulate_Gossip;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*     Procedure:  Emulate_Gossip                                           *)
(*                                                                          *)
(*     Purpose:    Provides split-screen gossip mode, dumb terminal         *)
(*                 emulation.                                               *)
(*                                                                          *)
(*     Calling sequence:                                                    *)
(*                                                                          *)
(*        Emulate_Gossip;                                                   *)
(*                                                                          *)
(*     Calls:                                                               *)
(*                                                                          *)
(*        Async_Receive                                                     *)
(*        Process_Command                                                   *)
(*        PibTerm_KeyPressed                                                *)
(*        Async_Send                                                        *)
(*        Display_Character                                                 *)
(*                                                                          *)
(*     Called by:                                                           *)
(*                                                                          *)
(*        PibTerm (Main)                                                    *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   MyX                  : INTEGER;
   MyY                  : INTEGER;
   YourX                : INTEGER;
   YourY                : INTEGER;
   Save_AutoWrap        : BOOLEAN;
   I                    : INTEGER;
   Comm_Ch              : CHAR;
   Done                 : BOOLEAN;
   My_Last_Column_Hit   : BOOLEAN;
   Your_Last_Column_Hit : BOOLEAN;
   G_Window_Size        : INTEGER;
   Divider_Line         : INTEGER;
   Top_Of_Bottom        : INTEGER;
   Input_Line           : AnyStr;
   Save_Ansi_Last_Line  : INTEGER;
   Reset_Requested      : BOOLEAN;
   ClrScr_Req           : BOOLEAN;
   TT                   : Transfer_Type;

(*--------------------------------------------------------------------------*)
(*       Display_Status_Message --- Display message for line mode           *)
(*--------------------------------------------------------------------------*)

PROCEDURE Display_Status_Message( Status_Text : AnyStr );

VAR
   Save_My_X: INTEGER;
   Save_My_Y: INTEGER;

BEGIN (* Display_Status_Message *)

   Save_My_X := MyX;
   Save_My_Y := MyY;

   WriteSXY( Status_Text, 55, Divider_Line, Global_Text_Attribute );

   MyX := Save_My_X;
   MyY := Save_My_Y;

END   (* Display_Status_Message *);

(*--------------------------------------------------------------------------*)
(*  Do_Gossip_Line_Mode --- Process keyboard input for gossip line mode     *)
(*--------------------------------------------------------------------------*)

PROCEDURE Do_Gossip_Line_Mode;

VAR
   Ch                    : CHAR;
   Save_Gossip_Line_Mode : BOOLEAN;

BEGIN (* Do_Gossip_Line_Mode *)
                                   (* Read in entire line *)
   IF PibTerm_KeyPressed THEN
      BEGIN

         PibTerm_Window( 1, Top_Of_Bottom, Max_Screen_Col, Ansi_Last_Line );
         GoToXY( MyX, MyY );
                                   (* Get first character *)
         Read_Kbd( Comm_Ch );

         IF ( Comm_Ch = CHR( CR ) ) THEN
            BEGIN
               Display_Status_Message(' Sending line ====');
               Async_Send_String( Input_Line );
               Input_Line := '';
               Display_Status_Message(' Line sent =======');
            END
         ELSE IF ( Comm_Ch = CHR( ESC ) ) THEN
            BEGIN
               Save_Gossip_Line_Mode := Gossip_Line_Mode;
               Process_Command( Comm_Ch, FALSE, PibTerm_Command );
               IF PibTerm_Command <> Null_Command THEN
                  Execute_Command( PibTerm_Command, Done, FALSE );
               IF ( Gossip_Line_Mode <> Save_Gossip_Line_Mode ) THEN
                  IF Gossip_Line_Mode THEN
                     Display_Status_Message(' Awaiting input ==' )
                  ELSE
                     Display_Status_Message('==================' );
            END
         ELSE
            BEGIN
               Display_Status_Message(' Reading keyboard ');
               Input_Line := Comm_Ch;
               Ch := Edit_String( Input_Line, 255, 1, 2, WhereY,
                                  Max_Screen_Col, FALSE, 0 );
               IF ( Ch <> CHR( ESC ) ) THEN
                  BEGIN
                     WRITELN;
                     Input_Line := Input_Line + CHR( CR );
                     Display_Status_Message(' Waiting to send =');
                  END
               ELSE
                  BEGIN
                     Input_Line := '';
                     Display_Status_Message(' Input cancelled ==');
                  END;
            END;
                                   (* Remember position! *)
            MyX := WhereX;
            MyY := WhereY;

         END;

END   (* Do_Gossip_Line_Mode *);

(*--------------------------------------------------------------------------*)
(*  Do_Gossip_Character_Mode --- Process kbd input for gossip char. mode    *)
(*--------------------------------------------------------------------------*)

PROCEDURE Do_Gossip_Character_Mode;

BEGIN (* Do_Gossip_Character_Mode *)

                                   (* Process local user's input      *)
   IF PibTerm_KeyPressed THEN
      BEGIN
                                   (* Move to local input window *)

         PibTerm_Window( 1, Top_Of_Bottom, Max_Screen_Col, Ansi_Last_Line );
         GoToXY( MyX, MyY );
                                   (* Handle input character *)

         Handle_Keyboard_Input( Done , Reset_Requested , ClrScr_Req );

         IF ( Reset_Requested OR ClrScr_Req ) THEN
            Clear_Window;

                                   (* Remember position! *)
         MyX := WhereX;
         MyY := WhereY;

      END (* PibTerm_KeyPressed *);

END   (* Do_Gossip_Character_Mode *);

(*--------------------------------------------------------------------------*)

BEGIN (* Emulate_Gossip *)
                                   (* Ensure we're in text mode *)

   Init_Text_Terminal;
                                   (* Set status line *)

   Set_Status_Line_Name(Short_Terminal_Name);

                                   (* Status line to last line *)

   Do_Status_Line      := Show_Status_Line;
   Do_Status_Time      := Do_Status_Line AND Show_Status_Time;
   Current_Status_Time := -1;

   IF Do_Status_Line THEN
      BEGIN
         Ansi_Last_Line := PRED( Max_Screen_Line );
         Write_To_Status_Line( Status_Line_Name, 1 );
         Update_Status_Line;
      END
   ELSE
      Ansi_Last_Line := Max_Screen_Line;

                                   (* Set initial positions for each  *)
                                   (* user's message area.            *)
   MyX            := 1;
   MyY            := 1;
   YourX          := 1;
   YourY          := 1;
   Done           := FALSE;
   Input_Line     := '';
   G_Window_Size  := Gossip_Window_Size;

                                   (* Ensure proper wrapping *)
   My_Last_Column_Hit   := FALSE;
   Your_Last_Column_Hit := FALSE;
   Save_AutoWrap        := Auto_Wrap_Mode;
   Auto_Wrap_Mode       := TRUE;

                                   (* Split screen into two parts:    *)
                                   (* Upper for local user, lower for *)
                                   (* remote user.                    *)

   PibTerm_Window( 1, 1, Max_Screen_Col, Ansi_Last_Line );
   Clear_Window;
                                   (* Print divider                   *)

   Divider_Line  := SUCC( G_Window_Size );
   Top_Of_Bottom := SUCC( Divider_Line  );

   GoToXY( 1 , Divider_Line );

   FOR I := 1 TO 34 DO WRITE('=');
   WRITE('Gossip Mode');
   FOR I := 1 TO 35 DO WRITE('=');

   IF Gossip_Line_Mode THEN
      Display_Status_Message(' Awaiting input ==' );

   Do_Script_Tests := Waitstring_Mode OR When_Mode OR
                      WaitCount_Mode  OR WaitQuiet_Mode OR
                      Script_Learn_Mode;

   REPEAT
                                   (* Process local user's input      *)
      IF Gossip_Line_Mode THEN
         Do_Gossip_Line_Mode
      ELSE
         Do_Gossip_Character_Mode;
                                   (* Process script file entry *)

      IF ( Script_File_Mode AND ( NOT ( Done OR Really_Wait_String ) ) ) THEN
         BEGIN
            Get_Script_Command( PibTerm_Command );
            Execute_Command   ( PibTerm_Command , Done , TRUE );
         END;
                                   (* Hold everything while scroll lock on *)
      IF Scroll_Lock_On THEN
         Handle_Scroll_Lock;
                                   (* Process remote user's input *)

      IF Async_Receive( Comm_Ch ) THEN

         BEGIN  (* Comm_Ch found *)

            Save_Ansi_Last_Line := Ansi_Last_Line;
            Ansi_Last_Line      := G_Window_Size;

            PibTerm_Window( 1, 1, Max_Screen_Col, G_Window_Size );
            GoToXY( YourX, YourY );

            Last_Column_Hit := Your_Last_Column_Hit;
            Comm_Ch         := TrTab[ Comm_Ch ];

            CASE ORD( Comm_Ch ) OF

               SOH : IF ( NOT Handle_Kermit_Autodownload ) THEN
                        Display_Character( Comm_Ch );

               CAN : IF ( NOT Handle_Zmodem_Autodownload ) THEN
                        Display_Character( Comm_Ch );

               ELSE  Display_Character( Comm_Ch );

            END (* CASE *);

            IF Do_Script_Tests THEN
               Do_Script_Checks( Comm_Ch );

            Your_Last_Column_Hit := Last_Column_Hit;
            Ansi_Last_Line       := Save_Ansi_Last_Line;

            YourX := WhereX;
            YourY := WhereY;

         END (* Comm_Ch found *)
                                   (* Check if waitstring time exhausted *)
      ELSE
         BEGIN
            Async_Line_Status := Async_Line_Status AND $FD;
            IF Really_Wait_String THEN
               Check_Wait_String_Time;
            IF ( NOT PibTerm_KeyPressed ) THEN
               GiveAwayTime( 1 );
         END;
                                    (* Send saved line if at left margin *)
      IF ( YourX = 1 ) THEN
         IF ( LENGTH( Input_Line ) > 0 ) THEN
            BEGIN
               Display_Status_Message(' Sending line ====');
               Async_Send_String( Input_Line );
               Input_Line := '';
               Display_Status_Message(' Line sent =======' );
            END;

   UNTIL ( NOT Gossip_Mode_On ) OR Done;

                                  (* Restore single screen mode *)

   Auto_Wrap_Mode      := Save_AutoWrap;

   PibTerm_Window( 1, 1, Max_Screen_Col, Ansi_Last_Line );
   Clear_Window;

END    (* Emulate_Gossip *);
