(*--------------------------------------------------------------------------*)
(*          Edit_String  -- Edit a string using keypad keys                 *)
(*--------------------------------------------------------------------------*)

FUNCTION Edit_String( VAR In_Str      : AnyStr;
                          Buffer_Len  : INTEGER;
                          Start_X     : INTEGER;
                          X           : INTEGER;
                          Y           : INTEGER;
                          MaxWidth    : INTEGER;
                          Force_Case  : BOOLEAN;
                          Status_Line : INTEGER  ) : CHAR;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*     Function:  Edit_String                                               *)
(*                                                                          *)
(*     Purpose:   Provides for editing a string using keypad keys.          *)
(*                                                                          *)
(*     Callling Sequence:                                                   *)
(*                                                                          *)
(*        Ch := Edit_String( VAR  In_Str     : AnyStr;                      *)
(*                                Buffer_Len : INTEGER;                     *)
(*                                Start_X    : INTEGER;                     *)
(*                                X          : INTEGER;                     *)
(*                                Y          : INTEGER;                     *)
(*                                MaxWidth   : INTEGER;                     *)
(*                                Force_Case : BOOLEAN;                     *)
(*                                Status_Line: INTEGER ) : CHAR;            *)
(*                                                                          *)
(*           In_Str      --- String to be edited                            *)
(*           Buffer_Len  --- Maximum length allowed for In_Str              *)
(*           Start_X     --- Column to display string                       *)
(*           X           --- Initial edit position in string                *)
(*           Y           --- Row to display string                          *)
(*           MaxWidth    --- Maximum width of display field for string      *)
(*                           being edited -- horizontal scrolling will be   *)
(*                           used if necessary.                             *)
(*           Force_Case  --- TRUE to force input to upper case              *)
(*           Status_Line --- Display edit status on this line if > 0;       *)
(*                           else no status line display.                   *)
(*           Ch          --- Character terminating edit of line             *)
(*                                                                          *)
(*     Calls:    DUPL                                                       *)
(*               GoToXY                                                     *)
(*               UpCase                                                     *)
(*               PibTerm_KeyPressed                                         *)
(*               Substr                                                     *)
(*               INSERT                                                     *)
(*               DELETE                                                     *)
(*               Read_Kbd_Old                                               *)
(*               MsDos                                                      *)
(*               Stuff_Kbd_Buf                                              *)
(*                                                                          *)
(*     Remarks:                                                             *)
(*                                                                          *)
(*        Here is a list of the control characters used (including IBM PC   *)
(*        function keys):                                                   *)
(*                                                                          *)
(*        ^A   Move back 1 word, nondestructive [Ctrl-LeftArrow]            *)
(*        ^B   Save current buffer in undo buffer                           *)
(*        ^C   End of input; accept what is currently visible [Ctrl-Break]  *)
(*        ^D   Move forward one [RightArrow]                                *)
(*        ^F   Move forward 1 word [Ctrl-RightArrow]                        *)
(*        ^G   Delete character forward [DEL]                               *)
(*        ^H   Move back 1, destructive (same as ASCII DEL) [BackSpace]     *)
(*        ^J   End of input; accept entire buffer [Ctrl-Enter]              *)
(*        ^L   Look for char: reads a character, advances cursor to match   *)
(*        ^M   End of input; accept text [Enter]                            *)
(*        ^P   Accept next character as-is (control character prefix)       *)
(*        ^Q   Move to beginning of line, nondestructive [Home]             *)
(*        ^R   Move to end of line [End]                                    *)
(*        ^S   Move back 1, nondestructive [LeftArrow]                      *)
(*        ^T   Delete line forward [Ctrl-End]                               *)
(*        ^U   Copy undo buffer into current buffer (undo)                  *)
(*        ^V   Insert on/off [INS]                                          *)
(*        ^Y   Delete line                                                  *)
(*        DEL  Move back 1, destructive (same as ^H) (ASCII DEL) [Ctrl-BS]  *)
(*        ESC  End of input; set result to null string and return.          *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

TYPE
   Edit_Record = RECORD
                    BufLen : BYTE;
                    S      : AnyStr;
                 END;

CONST
   ESC = ^[                        (* Escape character *);
   DEL = #$7F                      (* Delete character *);

(* STRUCTURED *) CONST
                                   (* Terminator characters *)

   TermChars : CharSet = [^C,^E,^J,^K,^M,^N,^[,^X];

                                   (* Legal chars in a 'word' *)

   WordChars : CharSet = ['0'..'9','A'..'Z','a'..'z'];

VAR
   Insert_Mode  : BOOLEAN           (* TRUE = insert mode, FALSE = overwrite *);
   WasChar      : BOOLEAN           (* TRUE if non-editing character         *);
   ReDraw       : BOOLEAN           (* TRUE to redraw line being edited      *);
   Ch           : CHAR              (* Current input editing character       *);
   In_Str_Undo  : AnyStr            (* Undo buffer                           *);
   In_String    : AnyStr            (* Working copy of string to be edited   *);
   I            : INTEGER           (* General loop counter                  *);
   L            : INTEGER           (* String length                         *);
   LOld         : INTEGER           (* String length before current edit     *);
   Regs         : Registers         (* For calling DOS function $0a          *);
   My_String    : Edit_Record       (* Edit record for DOS $0a editing       *);
   X2           : INTEGER           (* X position in searches                *);
   Disp_Length  : INTEGER           (* # of columns available for display    *);
   Left_X       : INTEGER           (* Current leftmost column displayed     *);
   First_Edit   : BOOLEAN           (* TRUE if first time editing string     *);
   Escape_Seen  : BOOLEAN           (* TRUE if escape sequence seen          *);

(*--------------------------------------------------------------------------*)

PROCEDURE Update_Edit_Status;

VAR
   SaveX: INTEGER;
   SaveY: INTEGER;

BEGIN (* Update_Edit_Status *)

   TextColor     ( Global_BackGround_Color );
   TextBackGround( Global_ForeGround_Color );

   SaveX := WhereX;
   SaveY := WhereY;

   GoToXY( 1 , Status_Line );

   WRITE(' Line ',Y:3,'   Column ',X:3);

   IF Insert_Mode THEN
      WRITE('  Insert   ')
   ELSE
      WRITE('  Overwrite');

   TextColor     ( Global_ForeGround_Color );
   TextBackGround( Global_BackGround_Color );

   ClrEol;

   GoToXY( SaveX, SaveY );

END   (* Update_Edit_Status *);

(*--------------------------------------------------------------------------*)

BEGIN (* Edit_String *)
                                   (* Use DOS function $0a if requested *)
   IF Use_Dos_Buffer_In THEN
      BEGIN
                                   (* Construct record for DOS $0a use  *)
         WITH My_String DO
            BEGIN
               S                        := In_Str;
               S[ SUCC( LENGTH( S ) ) ] := ^M;
               BufLen                   := 254;
            END;
                                   (* Move to position to display string *)
         GoToXY( Start_X , Y );
                                   (* Stuff F3 in keyboard buffer so string *)
                                   (* is displayed.                         *)

         Stuff_Kbd_Buf( F3 SHL 8 , TRUE );

                                   (* Call DOS to do the editing.           *)
         WITH Regs DO
            BEGIN

               AH := $0A;
               DS := SEG( My_String.BufLen );
               DX := OFS( My_String.BufLen );

               MsDos( Regs );

            END;

         Edit_String := ^M;               (* Return the terminator *)
         In_Str      := My_String.S;      (* Return updated string *)

         EXIT;

      END;
                                   (* Initialize -- not using DOS $0a *)

   Insert_Mode  := Edit_Insert_Mode;
   First_Edit   := Insert_Mode AND ( Start_X = X );

                                   (* Set cursor to block if overstrike *)
   IF ( NOT Insert_Mode ) THEN
      IF ( Font8x8Loaded OR ( Current_Video_Mode <> 7 ) ) THEN
         CursorSet( $0107 )
      ELSE
         CursorSet( $010D );
                                   (* Display the string to be edited *)
   In_String   := In_Str;
   In_Str_Undo := In_Str;

   GoToXY( Start_X , Y );

   LOld        := LENGTH( In_String );
   Left_X      := Start_X;

   WRITE( COPY( In_String, 1, MIN( LOld , MaxWidth ) ) );

   GoToXY( X , Y );
                                   (* Display status line if requested *)
   IF ( Status_Line > 0 ) THEN
      Update_Edit_Status;
                                   (* Begin main edit/input loop *)
   REPEAT
                                   (* Get current string length *)

      LOld   := LENGTH( In_String );

                                   (* Assume no need to redraw  *)
      ReDraw := FALSE;
                                   (* Read input character *)
      Read_Kbd_Old( Ch );
                                   (* Convert to upper case if requested *)
      IF Force_Case THEN
         Ch := UpCase( Ch );
                                   (* Assume editing char found *)
      WasChar := FALSE;
                                   (* No escape character yet *)
      Escape_Seen := FALSE;
                                   (* Check for keypad keys *)
      IF ( Ch = ESC ) THEN
         IF PibTerm_KeyPressed THEN
            BEGIN

               Escape_Seen := TRUE;

               Read_Kbd_Old( Ch );

               CASE ORD( Ch ) OF

                  Ctrl_L_Arrow : Ch := ^A;      (* Ctrl-LeftArrow  *)
                  R_Arrow      : Ch := ^D;      (* RightArrow      *)
                  Ctrl_R_Arrow : Ch := ^F;      (* Ctrl-RightArrow *)
                  Del_Key      : Ch := ^G;      (* DEL             *)
                  GlobType.Home: Ch := ^Q;      (* Home            *)
                  End_Key      : Ch := ^R;      (* END             *)
                  L_Arrow      : Ch := ^S;      (* LeftArrow       *)
                  Ctrl_End_Key : Ch := ^T;      (* Ctrl-END        *)
                  Ins_Key      : Ch := ^V;      (* INS             *)
                  U_Arrow      : Ch := ^E;      (* Up-arrow        *)
                  D_Arrow      : Ch := ^X;      (* Down-arrow      *)
                  PgUp         : Ch := ^U;      (* PgUp            *)
                  PgDn         : Ch := ^Y;      (* PgDn            *)
                  ELSE           Ch := '?';     (* all unknowns    *)
                                 Menu_Beep;

               END (* CASE *);
            END
         ELSE
            BEGIN
               ReDraw       := TRUE;
               In_String    := '';
               X            := Start_X;
            END;
                                   (* Perform editing function *)
      CASE Ch OF
                                   (* Move to beginning of string *)
         ^Q: X := Start_X;
                                   (* Restart editing *)
         ^U: BEGIN
                In_String := In_Str_Undo;
                X         := Start_X;
                ReDraw    := TRUE;
             END;

         ^Y: BEGIN
                In_String    := '';
                X            := Start_X;
                ReDraw       := TRUE;
             END;
                                   (* Move one word to left *)
         ^A: BEGIN
                X2 := X - Start_X;
                WHILE ( ( X2 > 0 ) AND
                        ( NOT ( In_String[X2] IN WordChars ) ) ) DO
                    DEC( X2 );
                IF ( X2 > 0 ) THEN DEC( X2 );
                WHILE ( ( X2 > 0 ) AND ( In_String[X2] IN WordChars ) ) DO
                   DEC( X2 );
                X := Start_X + X2;
             END;
                                   (* Save edited string in undo string *)

         ^B:  In_Str_Undo := In_String;

                                   (* Move 1 column to right *)

         ^D : IF (X - Start_X) < Buffer_Len THEN
                 IF ( ( X - Start_X ) < LOld ) THEN
                    INC( X );

                                   (* Move 1 word to right *)
         ^F:  BEGIN
                 X2 := SUCC( X - Start_X );
                 L  := LENGTH( In_String );
                 IF ( X2 < L ) THEN INC( X2 );
                 WHILE ( ( X2 <= L ) AND
                         ( In_String[X2] IN WordChars ) ) DO INC( X2 );
                 WHILE ( ( X2 <= L ) AND
                         ( NOT ( In_String[X2] IN WordChars ) ) ) DO INC( X2 );
                 X := PRED( Start_X + X2 );
              END;
                                   (* Search for character *)
         ^L:  BEGIN
                 Read_Kbd_Old( Ch );
                 L  := LOld;
                 X2 := X - Start_X + 2;
                 WHILE ( ( X2 <= L ) AND
                         ( In_String[X2] <> Ch ) ) DO INC( X2 );
                 IF ( X2 <= L ) THEN
                    X := PRED( Start_X + X2 );
                 Ch := ^L;
              END;
                                   (* Move to end of string *)
         ^R,
         ^N,
         ^J:  X := Start_X + LOld;

                                   (* Delete character under cursor *)
         ^G: BEGIN
                DELETE( In_String, X - PRED( Start_X ), 1 );
                ReDraw := TRUE;
             END;
                                   (* Destructive backspace *)
         ^H,
        DEL: IF ( X > Start_X ) THEN
                BEGIN
                   DELETE( In_String, X - Start_X, 1 );
                   DEC( X );
                   ReDraw := TRUE;
                END;
                                   (* Non-destructive backspace *)

         ^S: IF ( X > Start_X ) THEN DEC( X );

                                   (* Get control character *)
         ^P: BEGIN
                Read_Kbd_Old( Ch );
                WasChar := TRUE;
             END;
                                   (* Delete to end of line *)

         ^T: BEGIN
                DELETE( In_String, X - PRED( Start_X ), LOld );
                ReDraw := TRUE;
             END;
                                   (* Toggle Insert/Overwrite Mode *)

         ^V: BEGIN
                Insert_Mode := NOT Insert_Mode;
                IF ( NOT Insert_Mode ) THEN
                   IF ( Font8x8Loaded OR ( Current_Video_Mode <> 7 ) ) THEN
                      CursorSet( $0107 )
                   ELSE
                      CursorSet( $010D )
                ELSE
                   CursorOn;
             END;

         ELSE
             WasChar := NOT ( Ch IN TermChars ) AND
                        NOT ( Escape_Seen AND ( Ch = '?' ) );

      END (* CASE *);
                                   (* Ordinary character -- check if *)
                                   (* string must be extended.       *)
      IF WasChar THEN
         IF First_Edit THEN
            BEGIN
               In_String    := Ch;
               X            := SUCC( Start_X );
               ReDraw       := TRUE;
            END
         ELSE IF ( X - Start_X ) >= LOld THEN
            BEGIN
               In_String := In_String + Ch;
               IF( ( X - Start_X ) < MaxWidth ) THEN
                  BEGIN
                     GoToXY( X , Y );
                     WRITE( Ch );
                  END
               ELSE
                  ReDraw    := TRUE;
               IF ( X - Start_X ) < Buffer_Len THEN
                  INC( X );
            END
         ELSE
                                   (* If insert mode ... *)
            IF Insert_Mode THEN
               BEGIN

                  INSERT( Ch, In_String,
                          X - PRED( Start_X ) );

                  In_String := COPY( In_String, 1, Buffer_Len );

                  IF ( X - Start_X ) < Buffer_Len THEN
                     INC( X );

                  ReDraw := TRUE;

               END
            ELSE
               BEGIN   (* If Overwrite mode ... *)

                  In_String[ X - PRED( Start_X ) ] := Ch;

                  GoToXY( X , Y );
                  WRITE( Ch );

                  IF ( X - Start_X ) < Buffer_Len THEN
                     INC( X );

               END;
                                   (* Not first character edited any more *)
      First_Edit := FALSE;
                                   (* Set up horizontal scroll if needed *)

      L          := LENGTH( In_String );
      I          := Left_X;

      IF ( SUCC( X - Left_X ) > MaxWidth ) THEN
         WHILE ( SUCC( X - Left_X ) > MaxWidth ) DO
            INC( Left_X )
      ELSE
         WHILE ( X < Left_X ) DO
            DEC( Left_X );

      ReDraw := ReDraw OR ( I <> Left_X );

                                   (* Redraw line if needed *)
      IF ReDraw THEN
         BEGIN
            GoToXY( Start_X , Y );
            L := MIN( ( Left_X - Start_X + L ), MaxWidth );
            CursorOff;
            WRITE( COPY( In_String, SUCC( Left_X - Start_X ), L ) );
            L := SUCC( WhereX - Start_X );
            WHILE ( ( L <= MaxWidth ) AND ( Y = WhereY ) ) DO
               BEGIN
                  WRITE( ' ' );
                  INC( L );
               END;
            CursorOn;
         END;
                                   (* Update status line *)

      GoToXY( ( X - Left_X + Start_X ) , Y );

      IF ( Status_Line > 0 ) THEN
         Update_Edit_Status;

   UNTIL ( ( Ch IN TermChars ) AND ( NOT WasChar ) );

   Edit_String := Ch;                       (* Return the terminator *)
   In_Str      := In_String;                (* Return updated string *)

                                            (* Reset underline cursor *)
   CursorOn;

END   (* Edit_String *);
