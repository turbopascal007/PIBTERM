{
    QUICKB.INC - Quick B Protocol Support routines
          (derived from BPROTO.INC)

    Copyright 1987, CompuServe Incorporated

    These routines may be used as-is or in modified form in any
    personal computer terminal program to implement support of the
    CompuServe B and Quick B Protocols for the purpose of transfering
    information between CompuServe hosts and a personal computer.

    Implementation of B and/or Quick B Protocols in any host environment
    requires explicit licensing from CompuServe Incorporated.

    No warranty, expressed or implied, covers this code, or the specifications
    of the B and Quick B Protocols.


  Last update:
       Russ Ranshaw      10-Oct-87

  This source was originally derived from BP.C, written by
  Steve Wilhite, CompuServe Incorporated.

  Modified for PibTerm V4.0.7 by Philip R. Burns.   87-12-20.

}

(*----------------------------------------------------------------------*)
(*  Initialize_Transfer_Display --- Initialize transfer display window  *)
(*----------------------------------------------------------------------*)

PROCEDURE Initialize_Transfer_Display;

BEGIN (* Initialize_Transfer_Display *)

   Draw_Menu_Frame( 5, 10, 75, 20, Menu_Frame_Color, Menu_Title_Color,
                    Menu_Text_Color, Comp_Title );

   TextColor( Menu_Text_Color_2 );

   GoToXY( 1 , 1 );
   WRITE('Packets transferred: ');

   GoToXY( 1 , 2 );
   WRITE('Bytes transferred  : ');

   GoToXY( 1 , 3 );
   WRITE('Total errors       : ');

   GoToXY( 1 , 4 );

   IF ( NOT Receiving_File ) THEN
      WRITE('Bytes to send      : ');

   ClrEol;

   GoToXY( 1 , 5 );
   WRITE('Quick B protocol   : ');

   TextColor( Menu_Text_Color );

   IF Quick_B THEN
      WRITE('ON ')
   ELSE
      WRITE('OFF');

   TextColor( Menu_Text_Color_2 );

   GoToXY( 1 , 6 );
   WRITE('Block check type   : ');

   TextColor( Menu_Text_Color );

   IF Use_CRC THEN
      WRITE('16-bit CRC')
   ELSE
      WRITE('8-bit Checksum');
   ClrEol;

   TextColor( Menu_Text_Color_2 );

   GoToXY( 1 , 7 );
   WRITE('Block length       : ');

   TextColor( Menu_Text_Color );

   WRITE( Buffer_Size);
   ClrEol;

   TextColor( Menu_Text_Color_2 );

   GoToXY( 1 , 8 );
   WRITE('Send ahead         : ');

   TextColor( Menu_Text_Color );

   IF ( Our_WS <> 0 ) THEN
      WRITE('ON ')
   ELSE
      WRITE('OFF');

   TextColor( Menu_Text_Color_2 );

   GoToXY( 1 , Err_Mess_Line );
   WRITE('Last status message: ');
   ClrEol;

   CursorOff;

   TextColor( Menu_Text_Color );

   Write_Log( Comp_Title, FALSE, FALSE );

END   (* Initialize_Transfer_Display *);

(*----------------------------------------------------------------------*)
(*            Update_B_Display --- Update blocks received display       *)
(*----------------------------------------------------------------------*)

PROCEDURE Update_B_Display;

BEGIN (* Update_B_Display *)

   IF Display_Status THEN
      BEGIN

         TextColor( Menu_Text_Color );

         GoToXY( 22 , 1 );
         WRITE( Total_Packets );
         ClrEol;

         GoToXY( 22 , 2 );
         WRITE( Total_Bytes );
         ClrEol;

         GoToXY( 22 , 3 );
         WRITE( Total_Errors );
         ClrEol;

         IF ( NOT Receiving_File ) THEN
            BEGIN
               GoToXY( 22 , 4 );
               WRITE( TFile_Size );
               ClrEol;
            END;

      END;

END   (* Update_B_Display *);

(*----------------------------------------------------------------------*)
(*        Flip_Display_Status --- turn status display on/off            *)
(*----------------------------------------------------------------------*)

PROCEDURE Flip_Display_Status;

BEGIN (* Flip_Display_Status *)

   CASE Display_Status OF

      TRUE:   BEGIN
                                   (* Indicate no display   *)

                 Display_Status := FALSE;

                                   (* Remove display window  *)

                 Restore_Screen_And_Colors( Saved_Screen );

                                   (* Restore cursor *)
                 CursorOn;

              END;

      FALSE:  BEGIN
                                   (* Indicate display will be done *)

                 Display_Status := TRUE;

                                   (* Save screen image *)

                 Save_Partial_Screen( Saved_Screen, 5, 10, 75, 20 );

                                   (* Initialize display window     *)

                 Initialize_Transfer_Display;

              END;

   END (* CASE *);

END   (* Flip_Display_Status *);

(*----------------------------------------------------------------------*)
(*        Display_Message --- Display message in transfer window        *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Message( Message: AnyStr; Line : INTEGER );

BEGIN (* Display_Message *)

   IF ( NOT Display_Status ) THEN
      Flip_Display_Status;

   TextColor( Menu_Text_Color );

   GoToXY( 22 , Line );
   WRITE( Message );
   ClrEol;

   Write_Log( Message, TRUE, FALSE );

END   (* Display_Message *);

(*----------------------------------------------------------------------*)
(*     Display_Message_With_Number --- Display message with a number    *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Message_With_Number( Message: AnyStr; Number: INTEGER );

VAR
   S: STRING[10];

BEGIN (* Display_Message_With_Number *)

   IF ( NOT Display_Status ) THEN
      Flip_Display_Status;

   TextColor( Menu_Text_Color );

   GoToXY( 22 , Err_Mess_Line );
   WRITE( Message , Number );
   ClrEol;

   STR( Number , S );

   Write_Log( Message + S, TRUE, FALSE );

END   (* Display_Message_With_Number *);

(*----------------------------------------------------------------------*)
(*               Check_Keyboard --- Check for keyboard entry            *)
(*----------------------------------------------------------------------*)

PROCEDURE Check_Keyboard;

VAR
   Ch: CHAR;

BEGIN (* Check_Keyboard *)
                                   (* See if keyboard key depressed *)
   IF PibTerm_KeyPressed THEN
      BEGIN
                                   (* Yes -- read character *)
         Read_Kbd( Ch );
                                   (* If it is an escape, check  *)
                                   (* for extended key sequence. *)

         IF ( Ch = CHR( ESC ) ) THEN
            IF PibTerm_KeyPressed THEN
               BEGIN
                                   (* Handle extended key sequence *)
                  Read_Kbd( Ch );

                  CASE ORD( Ch ) OF
                     Alt_R:      IF Receiving_File THEN
                                    Halt_Transfer := TRUE;
                     Alt_S:      IF ( NOT Receiving_File ) THEN
                                    Halt_Transfer := TRUE;
                     Shift_Tab:  Flip_Display_Status;
                     ELSE        Handle_Function_Key( Ch );
                  END;

               END
            ELSE
                                   (* Plain ESC -- see if we're to clear *)
                                   (* XOFF received flag                 *)

               IF Async_XOff_Received THEN
                  Clear_XOFF_Received;

      END;
                                   (* Print something from spool file *)
                                   (* while we're here.               *)
   IF Print_Spooling THEN
      Print_Spooled_File;

END   (* Check_Keyboard *);

(*----------------------------------------------------------------------*)
(*            Do_CheckSum --- Do CRC or CheckSum calculation            *)
(*----------------------------------------------------------------------*)

PROCEDURE Do_CheckSum( Ch : INTEGER );

BEGIN (* Do_CheckSum *)

   IF ( Quick_B AND Use_CRC ) THEN
      BEGIN
         CheckSum := SWAP( CheckSum ) XOR Ch;
         CheckSum := CheckSum XOR ( LO( CheckSum ) SHR 4 );
         CheckSum := CheckSum XOR ( SWAP( LO( CheckSum ) ) SHL 4 ) XOR
                                  ( LO( CheckSum ) SHL 5 );
      END
   ELSE
      BEGIN

         CheckSum := CheckSum SHL 1;

         IF ( CheckSum > 255 ) THEN
            CheckSum := SUCC( CheckSum AND $FF );

         CheckSum := CheckSum + Ch;

         IF ( CheckSum > 255 ) THEN
            CheckSum := SUCC( CheckSum AND $FF );

      END;

END   (* Do_CheckSum *);

(*----------------------------------------------------------------------*)
(*               CISB_Term_ENQ --- Initialize CIS B Protocol            *)
(*----------------------------------------------------------------------*)

PROCEDURE CISB_Term_ENQ;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  CISB_Term_ENQ is called when the terminal emulator receives the     *)
(*  character <ENQ> from the host.  Its purpose is to initialize for    *)
(*  B Protocol and tell the host that we support Quick B.               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* CISB_Term_ENQ *)

   Seq_Num     := 0;
   Buffer_Size := 511;               { Set up defaults }
   Quick_B     := FALSE;             { Not Quick B Protocol }
   Use_CRC     := FALSE;             { Not CRC_16      }
   SA_Enabled  := FALSE;             { No Send-Ahead by us }
   SA_Max      := 1;                 { = single packet sent }

   Async_Send( CHR( DLE ) );
   Async_Send( '+' );

   Async_Send( CHR( DLE ) );
   Async_Send( '0' );

END  (* CISB_Term_ENQ *);

(*----------------------------------------------------------------------*)
(*            CISB_Term_ESC_I --- Handle <ESC>I sequence                *)
(*----------------------------------------------------------------------*)

PROCEDURE CISB_Term_ESC_I;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  CISB_Term_ESC_I is called when <ESC><I> is received by the terminal *)
(*  emulator.   Note that Quick B allows +XX to be added to the end of  *)
(*  the response, where XX is the two hex digits of the standard B      *)
(*  Protocol CheckSum of the preceeding characters in the response.     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   ESC_I_Response : STRING[12] = '#VCO,PB,DT,+';

VAR
   Save_Use_CRC : BOOLEAN;
   I            : INTEGER;
   T            : ShortStr;

BEGIN (* CISB_Term_ESC_I *)
                                   (* Save CRC setting, as this response *)
                                   (* is always sent using checksum.     *)
   Save_Use_CRC := Use_CRC;
   Use_CRC      := FALSE;
                                   (* Send <ESC>I text *)
   CheckSum := 0;

   FOR  I := 1 TO LENGTH( ESC_I_Response ) DO
      BEGIN
         Async_Send (      ESC_I_Response[ I ]   );
         Do_CheckSum( ORD( ESC_I_Response[ I ] ) );
      END;
                                   (* Append two hex digits of *)
                                   (* CheckSum to response     *)

   T := Dec_To_Hex( WORD( CheckSum ) );

   Async_Send( T[3] );
   Async_Send( T[4] );

   Async_Send( CHR( CR ) );
                                   (* Restore CRC flag *)
   Use_CRC := Save_Use_CRC;

END   (* CISB_Term_ESC_I *);

