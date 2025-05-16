(*----------------------------------------------------------------------*)
(*               Scroll --- Scroll section of screen                    *)
(*----------------------------------------------------------------------*)

PROCEDURE Scroll( Y1, Y2, X1, X2, Nlines, FG, BG : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Procedure: Scroll                                                  *)
(*                                                                      *)
(*   Purpose:   Scrolls portion of screen.                              *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      Scroll( Y1, Y2, X1, X2, Nlines, FG, BG : INTEGER );             *)
(*                                                                      *)
(*          (X1,Y1); (X2,Y2) --- corners of region to scroll            *)
(*          Nlines           --- number of lines to scroll              *)
(*          (FG,BG)          --- foreground and background colors       *)
(*                                                                      *)
(*   Calls:  INTR                                                       *)
(*                                                                      *)
(*   Remarks:                                                           *)
(*                                                                      *)
(*      The indicated portion of the screen is scrolled up or down.     *)
(*      If Nlines > 0, then the screen is scrolled up.  If Nlines < 0,  *)
(*      the screen is scrolled down.  Setting Nlines to zero blanks     *)
(*      the entire region.                                              *)
(*                                                                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Scroll *)

INLINE(
  $55                    {          PUSH   BP                ;Save BP}
                         {;}
  /$8A/$8E/>X1           {          MOV    Cl,[BP+>X1]       ;Get screen area to clear}
  /$FE/$C9               {          DEC    Cl}
  /$8A/$AE/>Y1           {          MOV    Ch,[BP+>Y1]}
  /$FE/$CD               {          DEC    Ch}
  /$8A/$96/>X2           {          MOV    Dl,[BP+>X2]}
  /$FE/$CA               {          DEC    Dl}
  /$8A/$B6/>Y2           {          MOV    Dh,[BP+>Y2]}
  /$FE/$CE               {          DEC    Dh}
                         {;}
  /$8A/$BE/>BG           {          MOV    Bh,[BP+>BG]       ;Get color for scrolled area}
  /$80/$E7/$7F           {          AND    Bh,$7F            ;Clear high-order bit.}
  /$D0/$E7               {          SHL    Bh,1}
  /$D0/$E7               {          SHL    Bh,1}
  /$D0/$E7               {          SHL    Bh,1}
  /$D0/$E7               {          SHL    Bh,1}
  /$0A/$BE/>FG           {          OR     Bh,[BP+>FG]}
                         {;}
  /$8B/$86/>NLINES       {          MOV    Ax,[BP+>NLines]   ;Get # of lines to scroll}
  /$3D/$00/$00           {          CMP    Ax,0              ;Figure direction of scroll}
  /$7D/$08               {          JGE    Scroll1}
  /$F7/$D8               {          NEG    Ax                ;ABS( Nlines )}
  /$0D/$00/$07           {          OR     Ax,$0700}
  /$E9/$03/$00           {          JMP    Scroll2}
                         {;}
  /$0D/$00/$06           {Scroll1:  OR     Ax,$0600}
                         {;}
  /$CD/$10               {Scroll2:  INT    $10               ;Call BIOS video interrupt}
                         {;}
  /$5D                   {          POP    BP                ;Restore BP}
);

END  (* Scroll *);
