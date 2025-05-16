(*----------------------------------------------------------------------*)
(*         Set_Display_Actions --- Set up display actions for emulation *)
(*----------------------------------------------------------------------*)

PROCEDURE Set_Display_Actions;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Set_Display_Actions                                  *)
(*                                                                      *)
(*     Purpose:    Set display actions for current emulation type       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Set_Display_Actions;                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Ch        : CHAR;
   I         : INTEGER;
   N         : INTEGER;
   P1        : Display_Action_Chars_Ptr;
   P2        : Display_Action_Actions_Ptr;
   F         : FILE;
   TDef_Name : AnyStr;

BEGIN (* Set_Display_Actions *)

                                   (* Assume no special actions as default *)

   FOR Ch := CHR( 0 ) TO CHR( 255 ) DO
      BEGIN
         Display_Action_Ptr[1]^  [ Ch ] := DisplayChar;
         Display_Char_Set_Ptr[1]^[ Ch ] := Ch;
      END;
                                   (* Assume second char set same as first *)

   MOVE( Display_Char_Set_Ptr[1]^, Display_Char_Set_Ptr[2]^, 256 );

                                   (* Start in state 1, character set 1    *)
   Display_Action_State  := 1;
   Character_Set_Ptr     := Display_Char_Set_Ptr[1];

                                   (* If user terminal definition, read    *)
                                   (* definition file.                     *)

   IF ( Terminal_To_Emulate IN [User1..User5] ) THEN
      BEGIN

         N := ORD( Terminal_To_Emulate ) - ORD( User1 ) + 1;

         TDef_Name := User_Term_Name[N];

         Add_Path( TDef_Name, Home_Dir, TDef_Name );

         ASSIGN( F , TDef_Name );
            (*!I-*)
         RESET( F );
            (*!I+*)

         IF ( INT24Result = 0 ) THEN
            BEGIN

               N := ORD( Terminal_To_Emulate );

                                   (* Get terminal name *)

               BlockRead( F, Long_Terminal_Names[N], 12 );
               Long_Terminal_Names[N][0] := CHR( 12 );

                                   (* Get # of display action vectors *)

               BlockRead( F, N, 2 );

                                   (* Read display action vector *)
               FOR I := 1 TO N DO
                  BEGIN
                     IF ( Display_Action_Ptr[I] = NIL ) THEN
                        NEW( Display_Action_Ptr[I] );
                     IF ( Display_Action_Ptr[I] <> NIL ) THEN
                        BlockRead( F, Display_Action_Ptr[I]^, 256 );
                  END;

                                   (* Get # of character sets *)

               BlockRead( F, N, 2 );

                                   (* Read character sets *)
               FOR I := 1 TO N DO
                  BEGIN
                     IF ( Display_Char_Set_Ptr[I] = NIL ) THEN
                        NEW( Display_Char_Set_Ptr[I] );
                     IF ( Display_Char_Set_Ptr[I] <> NIL ) THEN
                        BlockRead( F, Display_Char_Set_Ptr[I]^, 256 );
                  END;

            END
         ELSE
            BEGIN
               WRITELN;
               WRITELN('Can''t open terminal definition file ',TDef_Name);
               WRITELN('Dumb terminal assumed.');
               Terminal_To_Emulate := Dumb;
               Press_Any;
            END;

            (*!I-*)
        CLOSE( F );
            (*!I+*)

        I := INT24Result;

        EXIT;

      END;
                                   (* Else alter display information *)
                                   (* based upon terminal type       *)
   CASE Terminal_To_Emulate OF

      ADM3a:  BEGIN
                 N  := MaxAdm3aChars;
                 P1 := ADDR( ADM3a_Chars );
                 P2 := ADDR( ADM3a_Actions );
              END;

      ADM5:   BEGIN
                 N  := MaxAdm5Chars;
                 P1 := ADDR( ADM5_Chars );
                 P2 := ADDR( ADM5_Actions );
              END;

      VT52:   BEGIN
                 N  := MaxVT52Chars;
                 P1 := ADDR( VT52_Chars );
                 P2 := ADDR( VT52_Actions );
                 FOR I := 95 TO 126 DO
                    Display_Char_Set_Ptr[2]^[CHR(I)] := CHR(VT100_Graphics_Chars[I]);
                 Number_Tab_Stops := Number_VT52_Tabs;
                 MOVE( VT52_Tabs[1], Tab_Stops[1], Number_VT52_Tabs );
              END;

      TV925:  BEGIN
                 N  := MaxTV925Chars;
                 P1 := ADDR( TV925_Chars );
                 P2 := ADDR( TV925_Actions );
              END;

      ELSE
              N := 0;

   END (* CASE *);
                                   (* Insert information into vectors as needed *)
   FOR I := 1 TO N DO
      Display_Action_Ptr[1]^[P1^[I]] := P2^[I];

                                   (* Set CompuServe B protocol actions *)
   IF CompuServe_B_On THEN
      BEGIN
         Display_Action_Ptr[1]^[ CHR( DLE ) ] := DoCISBDLE;
         Display_Action_Ptr[1]^[ CHR( ETX ) ] := DoCISBENQ;
         Display_Action_Ptr[1]^[ CHR( ENQ ) ] := DoCISBENQ;
         Display_Action_Ptr[1]^[ 'I'        ] := DoCISBESCI;
      END;
                                   (* Set Zmodem protocol actions *)
   IF Zmodem_Autodownload THEN
      Display_Action_Ptr[1]^[ CHR( CAN ) ] := DoZmodemReceive;

                                   (* Set Kermit protocol actions *)
   IF Kermit_Autodownload THEN
         Display_Action_Ptr[1]^[ CHR( SOH ) ] := DoKermitReceive;

END   (* Set_Display_Actions *);
