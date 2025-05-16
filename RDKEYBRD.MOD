(*----------------------------------------------------------------------*)
(*  PibTerm_KeyPressed --- Replaces standard Turbo KeyPressed routine   *)
(*----------------------------------------------------------------------*)

FUNCTION PibTerm_KeyPressed : BOOLEAN;

VAR
   Regs : Registers;

(* STRUCTURED *) CONST
   XOFF_Message : STRING[13] = 'XOFF received';
   XON_Message  : STRING[13] = '             ';

BEGIN (* PibTerm_KeyPressed *)

   IF ( LENGTH( Keyboard_Buffer ) = 0 ) THEN
      BEGIN

         IF ( Extended_KeyBoard AND ( ( Mem[$40:$96] AND $10 ) <> 0 ) ) THEN
            Regs.Ah := $11
         ELSE
            Regs.Ah := 1;

         INTR( $16 , Regs );

         PibTerm_KeyPressed := ( ( Regs.Flags AND Zero_Flag ) = 0 );

      END
   ELSE
      BEGIN
         PibTerm_KeyPressed := Return_KeyPressed;
         Return_KeyPressed  := TRUE;
      END;

   IF Do_Status_Line THEN
      BEGIN
         IF Do_Status_Time THEN
            Update_Status_Line;
         IF Async_XOFF_Rec_Display THEN
            BEGIN
               Async_XOFF_Rec_Display := FALSE;
               Write_To_Status_Line( XOFF_Message , 65 );
            END;
         IF Async_XON_Rec_Display THEN
            BEGIN
               Async_XON_Rec_Display := FALSE;
               Write_To_Status_Line( XON_Message , 65 );
            END;
      END;

END   (* PibTerm_KeyPressed *);

(*----------------------------------------------------------------------*)
(*   ReadKeyboard --- Reads character from keyboard or PibTerm buffer   *)
(*----------------------------------------------------------------------*)

FUNCTION ReadKeyboard : CHAR;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   ReadKeyboard                                         *)
(*                                                                      *)
(*     Purpose:    Reads characters from keyboard or buffer             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ch := ReadKeyboard : CHAR;                                    *)
(*                                                                      *)
(*           Ch --- the character read                                  *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        INTR                                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   L       : INTEGER;
   Regs    : Registers;
   KCh     : CHAR;
   I       : INTEGER;
   Do_Ext  : BOOLEAN;

LABEL 1;

BEGIN (* ReadKeyboard *)
                                   (* Get length of internal keyboard *)
                                   (* buffer                          *)

   L := LENGTH( Keyboard_Buffer );

                                   (* If PibTerm's keyboard buffer *)
                                   (* not empty, read from it.     *)
   IF ( L > 0 ) THEN
      BEGIN

         KCh := Keyboard_Buffer[1];
         DELETE( Keyboard_Buffer, 1, 1 );
         DEC( L );
                                   (* Ensure keypressed flag set *)
                                   (* correctly.                 *)

         Return_KeyPressed := ( KCh <> CHR( ESC ) );

                                   (* Distinguish ESC sequence from *)
                                   (* "ordinary" ESC.               *)
         IF ( KCh = #$E0 ) THEN
            IF ( L > 0 ) THEN
               IF ( Keyboard_Buffer[1] = #$E0 ) THEN
                  BEGIN
                     KCh := CHR( ESC );
                     DELETE( Keyboard_Buffer, 1, 1 );
                  END;

      END
   ELSE
                                   (* PibTerm's buffer empty -- do *)
                                   (* actual keyboard read.        *)
      WITH Regs DO
         BEGIN
                                   (* BIOS read a character -- differs *)
                                   (* depending upon whether 84 or 101 *)
                                   (* key keyboard installed.          *)

            Do_Ext  := ( Extended_KeyBoard AND ( ( Mem[$40:$96] AND $10 ) <> 0 ) );

            IF Do_Ext THEN
               Ah := $10
            ELSE
               Ah := 0;

            INTR( $16 , Regs );
                                   (* If AL <> 0 Then it's ascii char *)
                                   (* else either CHR(0) or escape    *)
                                   (* sequence.  AH has scan code.    *)

            IF Do_Ext THEN
               FOR I := 1 TO Max_Extended_Keys DO
                  IF ( Regs.AX = Ext_AX_Vals[ I ] ) THEN
                     BEGIN
                        Regs.AX := Key_Values[ I ] SHL 8;
                        GOTO 1;
                     END;
1:
            IF ( NOT ( AL IN [0, $E0, $F0 ] ) ) THEN
               KCh := CHR( AL )
            ELSE IF ( AX = $0300 ) THEN
               KCh := CHR( 0 )
            ELSE
               BEGIN
                  KCh                := CHR( ESC );
                  Keyboard_Buffer[1] := CHR( AH );
                  Keyboard_Buffer[0] := CHR( 1 );
               END;

         END;
                                   (* Return current character *)
   ReadKeyboard := KCh;

END   (* ReadKeyboard *);
