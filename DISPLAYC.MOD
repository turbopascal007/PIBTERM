(*----------------------------------------------------------------------*)
(*           Display_Character --- show character received from port    *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Character( Ch: CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Display_Character                                    *)
(*                                                                      *)
(*     Purpose:    Displays character received from comm. port on       *)
(*                 screen/printer/capture file.                         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Display_Character( Ch : CHAR );                               *)
(*                                                                      *)
(*           Ch         --- Character received from Comm. port.         *)
(*                                                                      *)
(*      Calls:   Async_Receive                                          *)
(*               Min                                                    *)
(*               Update_Review_Pointers                                 *)
(*               TimeOfDay                                              *)
(*               TimeDiff                                               *)
(*                                                                      *)
(*      Remarks:                                                        *)
(*                                                                      *)
(*         This routine strips out certain characters which             *)
(*         should not be displayed, performs output line wrapping,      *)
(*         and saves the output line characters in the review buffer.   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

(* STRUCTURED *) CONST
   CR_Ch    : CHAR = ^M;
   LF_Ch    : CHAR = ^J;
   BL_Ch    : CHAR = ' ';
                                   (* Terminal types so effect of FF *)
                                   (* can be distinguished           *)
   Ansi_Set : SET OF Terminal_Type
              = [Ansi, VT52, VT100];

VAR
   I    : INTEGER;
   J    : INTEGER;
   L    : INTEGER;
   Xpos : INTEGER;
   Ypos : INTEGER;
   KeyC : CHAR;
   Disp : BOOLEAN;

(*----------------------------------------------------------------------*)
(*       MoveXY --- Move to (X,Y) on screen using BIOS call             *)
(*----------------------------------------------------------------------*)

PROCEDURE MoveXY( X: INTEGER; Y: INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  MoveXY                                               *)
(*                                                                      *)
(*     Purpose:    Moves to specified (X,Y) position on screen          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        MoveXY( X: INTEGER; Y: INTEGER );                             *)
(*                                                                      *)
(*           (X,Y)  --- Where to move to                                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* MoveXY *)

INLINE(
  $55/                   {  PUSH    BP}
  $B4/$02/               {  MOV     Ah,2                    ;BIOS position cursor function}
  $B7/$00/               {  MOV     Bh,0                    ;Page 0}
  $8A/$B6/>Y/            {  MOV     Dh,[BP+>Y]              ;Y coordinate}
  $FE/$CE/               {  DEC     Dh                      ;Drop by 1}
  $8A/$96/>X/            {  MOV     Dl,[BP+>X]              ;X coordinate}
  $FE/$CA/               {  DEC     Dl                      ;Drop by 1}
  $CD/$10/               {  INT     $10                     ;BIOS video interrupt}
  $5D);                  {  POP     BP}

END   (* MoveXY *);

(*----------------------------------------------------------------------*)

PROCEDURE Move_Chars_To_Right;

VAR
   I          : INTEGER;
   L          : INTEGER;
   C          : CHAR;
   CAttr      : BYTE;
   Hold_Chars : ARRAY[1..300] OF BYTE;

BEGIN (* Move_Chars_To_Right *)

   IF ( NOT Write_Screen_Memory ) THEN
      FOR I := ( Wrap_Screen_Col - 1 ) DOWNTO XPos DO
         BEGIN
            ReadCXY ( C, I, YPos, CAttr );
            WriteCXY( C, SUCC( I ), YPos, CAttr );
         END
   ELSE
      BEGIN
                                   (* Freeze screen for DoubleDos *)

         IF ( MultiTasker = DoubleDos ) THEN
            BEGIN
               TurnOffTimeSharing;
               Get_Screen_Address( DesqView_Screen );
            END;

         L := Wrap_Screen_Col - XPos;
         I := PRED( ( PRED( YPos ) * Max_Screen_Col + XPos ) SHL 1 );

         IF Wait_For_Retrace THEN
            BEGIN
               MoveFromScreen( DesqView_Screen^.Screen_Image[ I ],
                               Hold_Chars[1], L );
               MoveToScreen  ( Hold_Chars[1],
                               DesqView_Screen^.Screen_Image[ I + 2 ],
                               L );
            END
         ELSE
            MOVE( DesqView_Screen^.Screen_Image[ I ],
                  DesqView_Screen^.Screen_Image[ I + 2 ],
                  L SHL 1 );
                                   (* Unfreeze screen in DoubleDos *)

         IF ( MultiTasker = DoubleDos ) THEN
            TurnOnTimeSharing
                                   (* Synchronize screen for TopView *)

         ELSE IF ( MultiTasker = TopView ) THEN
            Sync_Screen( I , SUCC( L ) );

      END;

END   (* Move_Chars_To_Right *);

(*----------------------------------------------------------------------*)

BEGIN (* Display_Character *)
                                   (* Select display depending on *)
                                   (* character.                  *)
   Disp := FALSE;

   IF ( ( ORD( Ch ) < 32 ) AND ( NOT Graphics_Mode ) ) THEN
      CASE ORD( Ch ) OF

         CR   :    IF Add_LF THEN
                      BEGIN
                         IF Capture_On THEN
                            Capture_Char( LF_Ch );
                         IF Printer_On THEN
                            BEGIN
                               Write_Prt( CR_Ch );
                               Write_Prt( LF_Ch );
                            END;
                         WRITE( CR_Ch, LF_Ch );
                         Last_Column_Hit := FALSE;
                         IF Review_On THEN
                            Update_Review_Pointers;
                      END
                   ELSE
                      BEGIN
                         WRITE( CR_Ch );
                         Last_Column_Hit := FALSE;
                         IF Printer_On THEN
                            Write_Prt( CR_Ch );
                      END;

         LF   :    IF NOT Add_LF THEN
                      BEGIN
                         IF Capture_On THEN
                            Capture_Char( LF_Ch );
                         WRITE( LF_Ch );
                         IF Printer_On THEN
                            Write_Prt( LF_Ch );
                         IF Review_On THEN
                            Update_Review_Pointers;
                      END;

         BS   :    BEGIN
                      WRITE( Ch );
                      IF Capture_On THEN
                         Capture_Char( Ch );
                      IF Printer_On THEN
                         Write_Prt( Ch );
                      IF Review_On THEN
                         IF ( LENGTH( Review_Line ) > 0 ) THEN
                            DELETE( Review_Line, LENGTH( Review_Line ), 1 );
                   END;

         NUL  :    ;               (* Strip Nulls              *)

                                   (* Strip unattached XONs    *)
         XON  :    Disp := NOT Do_Xon_Xoff_Checks;

         BELL :    IF ( Not Silent_Mode ) THEN
                      Sound_Bell;

         HT   :    BEGIN

                      L := 9 - WhereX MOD 8;

                      FOR I := 1 TO L DO
                         BEGIN
                            WRITE( BL_Ch );
                            IF Review_On THEN
                               IF ( LENGTH( Review_Line ) < Max_Review_Line_Length ) THEN
                                  Review_Line := Review_Line + ' ';
                         END;

                      IF ( Capture_On AND Exact_Capture ) THEN
                         Capture_Char( Ch );

                      IF Printer_On THEN
                         FOR I := 1 TO L DO
                            Write_Prt( BL_Ch );

                   END;

         VT, FF:   BEGIN
                      IF Capture_On THEN
                         Capture_Char( Ch );
                      IF Printer_On THEN
                         Write_Prt( Ch );
                      IF ( NOT ( Terminal_To_Emulate IN Ansi_Set ) ) THEN
                         Clear_Window
                      ELSE
                         BEGIN
                            WRITE( LF_Ch );
                            IF Review_On THEN
                               Update_Review_Pointers;
                         END;
                   END;

         ELSE
                   Disp := TRUE;

      END (* CASE *)
   ELSE
      Disp := TRUE;

   IF Disp AND ( ORD( Ch ) <> DEL ) THEN
      BEGIN

         XPos := WhereX + PRED( Upper_Left_Column );
         YPos := WhereY + PRED( Upper_Left_Row    );

         IF ( XPos < Wrap_Screen_Col ) THEN
            BEGIN
               IF Insertion_Mode THEN
                  Move_Chars_To_Right;
               WriteCXY( Ch, XPos, YPos, Global_Text_Attribute );
               MoveXY( SUCC( XPos ) , YPos );
               Last_Column_Hit := FALSE;
            END
         ELSE
            BEGIN
               IF Auto_Wrap_Mode THEN
                  BEGIN
                     IF Last_Column_Hit THEN
                        BEGIN
                           IF ( Capture_On AND ( NOT Exact_Capture ) ) THEN
                              Capture_Char( CHR( LF ) );
                           WRITELN;
                           XPos            := WhereX + PRED( Upper_Left_Column );
                           YPos            := WhereY + PRED( Upper_Left_Row    );
                        END;
                     Last_Column_Hit := NOT Last_Column_Hit;
                     WriteCXY( Ch, XPos, YPos, Global_Text_Attribute );
                     IF ( NOT Last_Column_Hit ) THEN
                        MoveXY( SUCC( XPos ) , YPos );
                  END
               ELSE
                  BEGIN
                     WriteCXY( Ch, Wrap_Screen_Col, YPos, Global_Text_Attribute );
                     Last_Column_Hit := TRUE;
                  END;
            END;

         IF Review_On THEN
            IF ( LENGTH( Review_Line ) < Max_Review_Line_Length ) THEN
               Review_Line := Review_Line + Ch;

         IF Capture_On THEN
            Capture_Char( Ch );

         IF Printer_On THEN
            Write_Prt( Ch );

      END;

END   (* Display_Character *);
