(*----------------------------------------------------------------------*)
(*     Kermit_Remote_Commands --- Finish server mode transfers          *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Remote_Commands(     Remote_Command : AnyStr;
                                  VAR Do_A_Receive   : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Kermit_Remote_Commands                               *)
(*                                                                      *)
(*     Purpose:    Issues commands to remote server                     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Kermit_Remote_Commands(     Remote_Command : AnyStr;          *)
(*                                VAR Do_A_Receive   : BOOLEAN );       *)
(*                                                                      *)
(*           Remote_Command --- Server command to execute               *)
(*           Do_A_Receive   --- TRUE on exit if file transfer needs     *)
(*                              to be executed.                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Try                : INTEGER;
   Ch                 : CHAR;
   Command_Menu       : Menu_Type;
   Command            : INTEGER;
   Param_S1           : AnyStr;
   Param_S2           : AnyStr;
   Quit               : BOOLEAN;
   Ack_OK             : BOOLEAN;
   Save_Display       : BOOLEAN;
   Local_Save         : Saved_Screen_Ptr;
   Packet_Buffer_Data : AnyStr;

CONST
   Quit_Item           = 11;
   Max_Remote_Commands = 10;

(* STRUCTURED *) CONST             (* Long names for display *)

   Remote_Command_Names: ARRAY[1..Max_Remote_Commands] OF STRING[16] =
                         ( 'Change Directory',
                           'Delete File',
                           'Directory',
                           'Finish Server',
                           'Help',
                           'Host',
                           'Logout Server',
                           'Space',
                           'Type',
                           'Who' );

                                   (* Short names for parsing *)

   Remote_Command_Short_Names: ARRAY[1..Max_Remote_Commands] OF STRING[9] =
                               ( 'CWD',
                                 'DELETE',
                                 'DIRECTORY',
                                 'FINISH',
                                 'HELP',
                                 'HOST',
                                 'LOGOUT',
                                 'SPACE',
                                 'TYPE',
                                 'WHO' );

                                   (* # params for each command *)

   KParams : ARRAY[1..Max_Remote_Commands] OF BYTE =
             ( 2, 1, 1, 0, 1, 1, 0, 1, 1, 2 );

                                   (* Command letters each command *)

   KLetters: ARRAY[1..Max_Remote_Commands] OF STRING[2] =
             ( 'GC', 'GE', 'GD', 'GF', 'GH', 'C', 'GL', 'GU', 'GT', 'GW' );

(*----------------------------------------------------------------------*)
(*     Check_Remote_Return --- Check returned packet from remote        *)
(*----------------------------------------------------------------------*)

PROCEDURE Check_Remote_Return;

BEGIN (* Check_Remote_Return *)
                                   (* Pick up a packet           *)
   Receive_Packet;

   IF Packet_OK AND ( NOT Kermit_Abort ) THEN
      BEGIN
                                   (* Check if ACK or NAK packet received. *)
                                   (* May also be error packet.            *)

         CASE Kermit_Packet_Type OF

                                   (* Make sure ACK is for correct block *)

            ACK_Pack :   IF ( Rec_Packet_Num = ( Packet_Num MOD 64 ) ) THEN
                            BEGIN
                               ACK_OK := TRUE;
                               IF ( Rec_Packet_Length > 0 ) THEN
                                  BEGIN
                                     WRITELN;
                                     Write_Log('Remote Kermit replies: ' +
                                               COPY( Rec_Packet_Ptr^[1], 1,
                                                     Rec_Packet_Length ) ,
                                               FALSE, TRUE );
                                  END;
                               Window_Delay;
                            END;

                                   (* Error packet sent *)
            Error_Pack : BEGIN
                            WRITELN;
                            Write_Log('Error from remote Kermit: ' +
                                       COPY( Rec_Packet_Ptr^[1], 1, Rec_Packet_Length ),
                                       FALSE, TRUE );
                            Window_Delay;
                         END;

             Send_Pack : BEGIN
                            Ack_OK := TRUE;
                         END;
                                   (* Something else -- don't ACK it *)
            ELSE
               ACK_OK := FALSE;

         END (* CASE *)

      END
   ELSE
      ACK_OK := FALSE;

END   (* Check_Remote_Return *);

(*----------------------------------------------------------------------*)
(*     Get_Remote_Command --- Prompt for remote command to execute      *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Remote_Command;

BEGIN (* Get_Remote_Command *)
                                   (* Save current screen *)

   Save_Screen( Local_Save );
                                   (* Display menu of remote commands *)

   Make_And_Display_Menu( Command_Menu, Quit_Item, 6, 20, 0, 0, Quit_Item,
                          'Remote Kermit commands: ',
                          'Change Directory;Delete File;Directory;Finish;Help;Host;Logout;Space;Type;Who;Quit;',
                          TRUE, TRUE, Command );

   Quit := FALSE;

   IF ( Command > 0 ) AND ( Command < Quit_Item ) THEN
      BEGIN

         Draw_Menu_Frame( 15, 5, 75, 11, Menu_Frame_Color, Menu_Title_Color,
                          Menu_Text_Color, 'Kermit ' +
                          Remote_Command_Names[Command] );

         PibTerm_Window( 16, 6, 74, 10 );

         GoToXY( 1 , 1 );

         Packet_Buffer_Data := KLetters[ Command ];

      END
   ELSE
      Quit := TRUE;

   IF ( ( KParams[Command] > 0 ) AND ( NOT Quit ) ) THEN
      BEGIN

         Param_S1           := '';
         Param_S2           := '';

         CASE Command OF
            1 : WRITELN(' Enter directory specification: ');
            2 : WRITELN(' Enter name of file to delete:  ');
            3 : WRITELN(' Enter directory specification: ');
            5 : WRITELN(' Enter topic to get help about: ');
            6 : WRITELN(' Enter host command:            ');
            8 : WRITELN(' Enter area:                    ');
            9 : WRITELN(' Enter file to type:            ');
            10: WRITELN(' Enter userid:                  ');
         END (* CASE *);

         WRITE('> ');
         Read_Edited_String( Param_S1 );
         WRITELN;

         IF ( LENGTH( Param_S1 ) > 0 ) THEN
            Quit := ( Param_S1[1] = CHR( ESC ) );

         IF ( ( KParams[Command] > 1 ) AND ( NOT Quit ) ) THEN
            BEGIN

               CASE Command OF
                  1 : WRITELN(' Enter password:                ');
                  10: WRITELN(' Enter options:                 ');
                  ELSE;
               END (* CASE *);

               WRITE('> ');
               Read_Edited_String( Param_S2 );
               WRITELN;

               IF ( LENGTH( Param_S2 ) > 0 ) THEN
                  Quit := ( Param_S2[1] = CHR( ESC ) );

            END;

      END (* NOT Quit *);
                                   (* Remove selection window       *)

   Restore_Screen_And_Colors( Local_Save );

END   (* Get_Remote_Command *);

(*----------------------------------------------------------------------*)
(*     Parse_Remote_Command --- Parse remote command to execute         *)
(*----------------------------------------------------------------------*)

PROCEDURE Parse_Remote_Command;

VAR
   IPos  : INTEGER;
   CName : ShortStr;
   I     : INTEGER;
   L     : INTEGER;


BEGIN (* Parse_Remote_Command *)

   Remote_Command := COPY( Remote_Command, 2, LENGTH( Remote_Command ) - 1 );
   L              := LENGTH( Remote_Command );
   Param_S1       := '';
   Param_S2       := '';

   IPos  := POS( ' ' , Remote_Command );

   IF ( IPos > 0 ) THEN
      BEGIN
         CName          := COPY( Remote_Command , 1 , IPos - 1 );
         Remote_Command := Trim( COPY( Remote_Command , IPos + 1 , L - IPos ) );
      END
   ELSE
      BEGIN
         CName          := Remote_Command;
         Remote_Command := '';
      END;

   CName   := UpperCase( Trim( CName ) );
   Command := 0;

   FOR I := 1 TO Max_Remote_Commands DO
      IF ( CName = Remote_Command_Short_Names[I] ) THEN
         Command := I;

   IF ( Command = 0 ) THEN
      Quit := TRUE
   ELSE
      BEGIN

         Quit := FALSE;

         IF ( KParams[Command] = 1 ) THEN
            Param_S1 := Remote_Command
         ELSE
            BEGIN

               IPos  := POS( ' ' , Remote_Command );

               IF ( IPos = 0 ) THEN
                  Param_S1 := Remote_Command
               ELSE
                  BEGIN
                     Param_S1 := Trim( COPY( Remote_Command , 1 , IPos - 1 ) );
                     Param_S2 := Trim( COPY( Remote_Command, IPos + 1,
                                       LENGTH( Remote_Command ) - IPos ) );
                  END;

            END;

      END;

END   (* Parse_Remote_Command *);

(*----------------------------------------------------------------------*)

BEGIN (* Kermit_Remote_Commands *)

                                   (* If command line not passed in, *)
                                   (* prompt for command.            *)

   IF ( LENGTH( Remote_Command ) = 0 ) THEN
      Get_Remote_Command
   ELSE
      Parse_Remote_Command;
                                   (* Send command to remote server  *)
   IF Quit THEN
      Do_A_Receive := FALSE
   ELSE
      BEGIN
                                   (* Construct command packet *)

         Packet_Buffer_Data := KLetters[ Command ];

         IF ( Command = 6 ) THEN
            Packet_Buffer_Data := Packet_Buffer_Data + Param_S1
         ELSE
            BEGIN

               IF ( LENGTH( Param_S1 ) > 0 ) THEN
                  Packet_Buffer_Data := Packet_Buffer_Data +
                                        CHR( LENGTH( Param_S1 ) + 32 ) +
                                        Param_S1;

               IF ( LENGTH( Param_S2 ) > 0 ) THEN
                  Packet_Buffer_Data := Packet_Buffer_Data +
                                        CHR( LENGTH( Param_S2 ) + 32 ) +
                                        Param_S2;

            END;

         Write_Log( 'Remote Kermit command = '    +
                     Remote_Command_Names[Command] + ' ' +
                     Param_S1 + ' ' +
                     Param_S2,
                     FALSE, FALSE );

         Packet_Num          := 0;
         Try                 := 0;
         Packets_Received    := 0;
         Packets_Sent        := 0;
         Packets_Bad         := 0;
         Kermit_MaxTry       := 5;
         Kermit_Abort        := FALSE;
         Kermit_Retry        := FALSE;
         Kermit_Abort_Level  := No_Abort;
         Kermit_Screen_Write := FALSE;
         His_Chk_Type        := '1';

         Send_Packet_Length  := LENGTH( Packet_Buffer_Data );

         MOVE( Packet_Buffer_Data[1], Send_Packet_Ptr^[4], Send_Packet_Length );

         Send_Packet_Length  := Send_Packet_Length + 3;

         Build_Packet;

         Save_Display   := Display_Status;
         Display_Status := FALSE;

         REPEAT

            Try := Try + 1;

            Send_Packet;

            Check_Remote_Return;

         UNTIL ( Kermit_Abort OR ACK_OK OR ( Try > Kermit_MaxTry ) );

         Do_A_Receive := ( Try <= Kermit_MaxTry ) AND
                         ( Kermit_Packet_Type = Send_Pack ) AND
                         ( NOT Kermit_Abort );

         Display_Status := Save_Display;

     END;

END    (* Kermit_Remote_Commands *);
