(*---------------------------------------------------------------------*)
(*       Clr_Kbd_Buf --- Clear contents of keyboard buffer             *)
(*---------------------------------------------------------------------*)

PROCEDURE Clr_Kbd_Buf;

VAR
   Kbd_Head  : BYTE ABSOLUTE $0000:$041A;
   Kbd_Tail  : BYTE ABSOLUTE $0000:$041C;

BEGIN (* Clr_Kbd_Buf *)

   Kbd_Head := Kbd_Tail;

END   (* Clr_Kbd_Buf *);

(*---------------------------------------------------------------------*)
(*       Stuff_Kbd_Buf --- Stuff a character in keyboard buffer        *)
(*---------------------------------------------------------------------*)

PROCEDURE Stuff_Kbd_Buf( In_Chr: INTEGER; Clr_Kbd : BOOLEAN );

VAR
   Bool_Val : BOOLEAN;

    {  Causes a character to be received as if a key had been pressed.
       In_Chr is an integer representing the character to be received.
       If the character is an ASCII character or part of the extended
       character set (#128..#255) the integer will be in the range
       0..255. If a `special' key, function key or Alt key combination
       is to be received In_Chr should equal the scan code of the
       desired key * 256. e.g. The scan code for <Alt><1> is 120 decimal
       $78 hex, so In_Chr should be 30720 decimal or $7800 hex to produce
       the effect of pressing <Alt><1>. }

BEGIN (* Stuff_Kbd_Buf *)
                                   (* Clear keyboard if desired *)
   IF Clr_Kbd THEN
      Clr_Kbd_Buf;

   INLINE
      ($1E/             (*      PUSH    DS          Save DS and change it      *)
       $B8/$40/$00/     (*      MOV     AX,0040     to point to seg 0040:      *)
       $8E/$D8/         (*      MOV     DS,AX                                  *)
       $FA/             (*      CLI                 Clear interrupt flag       *)
       $8B/$46/$06/     (*      MOV     AX,[BP+06]  Move character to AX       *)
       $8B/$1E/$1C/$00/ (*      MOV     BX,[001Ch]  Move kb buf tail Ofs to BX *)
       $89/$07/         (*      MOV     [BX],AX     Put character in buffer.   *)
       $83/$C3/$02/     (*      ADD     BX,+2       Increment tail pntr by 2.  *)
       $3B/$1E/$82/$00/ (*      CMP     BX,[0082h]  Compare BX with [0040:0082]*)
       $74/$07/         (*      JZ      CIRC        Jump if end of buffer.     *)
       $89/$1E/$1C/$00/ (*      MOV     [001Ch],BX  Update address of tail.    *)
       $EB/$09/$90/     (*      JMP     EXIT        Exit                       *)
       $8B/$1E/$80/$00/ (*CIRC: MOV     BX,[0080h]  Set BX to start of buffer. *)
       $89/$1E/$1C/$00/ (*      MOV     [001Ch],BX  Update address of tail.    *)
       $FB/             (*EXIT: STI                 Set interrupt flag.        *)
       $1F);            (*      POP     DS          Restore DS.                *)

                                   (* Ensure keyboard input noticed *)
   Bool_Val := PibTerm_KeyPressed;

END    (* Stuff_Kbd_Buf *);
