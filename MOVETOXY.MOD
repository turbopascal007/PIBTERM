(*----------------------------------------------------------------------*)
(*       MoveToXY --- Move to (X,Y) on screen using BIOS call           *)
(*----------------------------------------------------------------------*)

PROCEDURE MoveToXY( X: INTEGER; Y: INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  MoveToXY                                             *)
(*                                                                      *)
(*     Purpose:    Moves to specified (X,Y) position on screen          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        MoveToXY( X: INTEGER; Y: INTEGER );                           *)
(*                                                                      *)
(*           (X,Y)  --- Where to move to                                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* MoveToXY *)

INLINE(
  $B4/$02                    {   MOV     Ah,2                    ;BIOS position cursor function}
  /$B7/$00                   {   MOV     Bh,0                    ;Page 0}
  /$8A/$B6/>Y                {   MOV     Dh,[BP+>Y]              ;Y coordinate}
  /$FE/$CE                   {   DEC     Dh                      ;Drop by 1}
  /$02/$36/>UPPER_LEFT_ROW   {   ADD     Dh,[>Upper_Left_Row]    ;Add in Turbo window row offset}
  /$FE/$CE                   {   DEC     Dh                      ;Drop by 1}
  /$8A/$96/>X                {   MOV     Dl,[BP+>X]              ;X coordinate}
  /$FE/$CA                   {   DEC     Dl                      ;Drop by 1}
  /$02/$16/>UPPER_LEFT_COLUMN{   ADD     DL,[>Upper_Left_Column] ;Add in Turbo window column offset}
  /$FE/$CA                   {   DEC     Dl                      ;Drop by 1}
  /$CD/$10                   {   INT     $10                     ;BIOS video interrupt}
      );

END   (* MoveToXY *);
