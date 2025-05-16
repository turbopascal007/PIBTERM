(*--------------------------------------------------------------------------*)
(*             PIBMDOS.PAS --- Multitasker interface routines               *)
(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*  Author:  Philip R. Burns                                                *)
(*                                                                          *)
(*  Date:    Version 1.0: January, 1986.   DoubleDos support.               *)
(*           Version 2.0: April, 1986.     Add DesqView support.            *)
(*           Version 3.0: July, 1986.      Add TopView/Windows support.     *)
(*           Version 3.1: September, 1986. Update for TaskView support.     *)
(*           Version 3.2: December, 1986.  Distinguish TaskView/DesqView.   *)
(*           Version 4.0: January, 1988.   Fix bogus TopView update, add    *)
(*                                         check for Novell to stop lockup. *)
(*                                                                          *)
(*  Systems: MS DOS or PC DOS with DoubleDos/DesqView/TopView/Windows       *)
(*           installed.                                                     *)
(*                                                                          *)
(*  History: These routines provide a simple interface for PibTerm          *)
(*           with SoftLogic's DoubleDos multitasking executive,             *)
(*           Quarterdeck's DesqView multitasker, IBM's TopView,             *)
(*           MicroSoft's Windows, and Sunny Hill's TaskView.                *)
(*           (Windows is handled as a Topview-emulating product.  This is   *)
(*           also true for TaskView and DesqView, but those programs do     *)
(*           not require the explicit screen updates TopView requires.      *)
(*                                                                          *)
(*           If you have another multitasker, you should be able to         *)
(*           replace these routines fairly easily with similar-acting       *)
(*           ones for your multitasker.  Use the global types defined       *)
(*           for MultiTasker and MultiTaskerType.                           *)
(*                                                                          *)
(*           Note also that the routine Get_Screen_Address in Pibscren.pas  *)
(*           needs to know about multitaskers.                              *)
(*                                                                          *)
(*           With DoubleDos, it is necessary to reobtain the display buffer *)
(*           address every time the screen memory is written to.  With      *)
(*           DesqView, this is unnecessary.  With TopView and Windows,      *)
(*           it is necessary to inform them that the screen has changed.    *)
(*           TaskView works like DesqView.                                  *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*           Please leave messages on Gene Plantz's BBS (312) 882 4145      *)
(*           or Ron Fox's BBS (312) 940 6496.                               *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

(*--------------------------------------------------------------------------*)
(*           IsNovellActive  --- Checks if Novell network is active         *)
(*--------------------------------------------------------------------------*)

FUNCTION IsNovellActive : BOOLEAN;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*    Function: IsNovellActive                                              *)
(*                                                                          *)
(*    Purpose:  Checks if Novell network active                             *)
(*                                                                          *)
(*    Calling Sequence:                                                     *)
(*                                                                          *)
(*       Novell_On := IsNovellActive : BOOLEAN;                             *)
(*                                                                          *)
(*          Novell_On --- TRUE if Novell network is active.                 *)
(*                                                                          *)
(*    Calls:  MsDos                                                         *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   Regs : Registers;

BEGIN (* IsNovellActive *)

   Regs.CX := 0;
   Regs.AL := 0;
                                   (* Request workstation ID.          *)
                                   (* This should be ignored if Novell *)
                                   (* network software isn't active.   *)
   Regs.AH := $DC;

   MsDos( Regs );
                                   (* If we got back a non-zero station *)
                                   (* ID, then Novell must be loaded.   *)

   IsNovellActive := ( Regs.AL <> 0 );

END   (* IsNovellActive *);

(*--------------------------------------------------------------------------*)
(*           IsTimeSharingActive --- Checks if multitasker is active        *)
(*--------------------------------------------------------------------------*)

FUNCTION IsTimeSharingActive : BOOLEAN;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*    Function: IsTimeSharingActive                                         *)
(*                                                                          *)
(*    Purpose:  Checks if multitasker is active                             *)
(*                                                                          *)
(*    Calling Sequence:                                                     *)
(*                                                                          *)
(*       Ts_On := IsTimeSharingActive : BOOLEAN;                            *)
(*                                                                          *)
(*          Ts_On --- TRUE if multitasker is active.                        *)
(*                                                                          *)
(*    Calls:  MsDos                                                         *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   Regs : Registers;

(*--------------------------------------------------------------------------*)

FUNCTION Get_TopView_Screen_Address : BOOLEAN;

VAR
   SegS : INTEGER;
   SegO : INTEGER;

BEGIN (* Get_TopView_Screen_Address *)

   Regs.Di := 0;
   Regs.Ax := $FE00;
   Regs.Es := SEG( DesqView_Screen^ );

   SegO    := 0;
   SegS    := Regs.Es;

   INTR( $10 , Regs );

   DesqView_Screen := PTR( Regs.Es , Regs.Di );

   Get_TopView_Screen_Address := ( ( Regs.Es <> SegS ) OR ( Regs.Di <> SegO ) );

END   (* Get_TopView_Screen_Address *);

(*--------------------------------------------------------------------------*)

BEGIN (* IsTimeSharingActive *)
                                   (* Assume timesharing not active *)
   IsTimeSharingActive := FALSE;
   MultiTasker         := MultiTasker_None;

                                   (* Determine if color or mono screen *)
   Regs.Ax := 15 SHL 8;
   INTR( $10 , Regs );
                                   (* Get initial screen address    *)
   IF ( Regs.AL <> 7 ) THEN
      DesqView_Screen := PTR( Color_Screen_Address , 0 )
   ELSE
      DesqView_Screen := PTR( Mono_Screen_Address  , 0 );

                                   (* If Novell network not active, *)
                                   (* check if DoubleDos is active. *)
   IF ( NOT IsNovellActive ) THEN
      BEGIN
                                   (* If DDos is active, $E4 should *)
                                   (* return a non-zero value in Al *)
         Regs.Ax := $E400;

         MsDos( Regs );

         IF ( Regs.Al <> 0 ) THEN
            BEGIN
               IsTimeSharingActive := TRUE;
               MultiTasker         := DoubleDos;
               EXIT;
            END;

      END;
                                   (* See if DesqView is active.        *)
                                   (* We do a time/date call with       *)
                                   (* DESQ as date.  If DesqView is     *)
                                   (* active, this will be accepted.    *)
                                   (* If not, it returns as invalid.    *)
                                   (* While we're at it, get the        *)
                                   (* display buffer address, which     *)
                                   (* never changes.                    *)
                                   (*                                   *)
                                   (* NOTE:  Newer versions of TaskView *)
                                   (*        also accept this DesqView  *)
                                   (*        call, so we must check the *)
                                   (*        TopView number to differ-  *)
                                   (*        entiate them.              *)
   Regs.Ax := $2B01;
   Regs.Cx := $4445;  (*'DE'*)
   Regs.Dx := $5351;  (*'SQ'*)
   MsDos( Regs );

   IF ( Regs.Al <> $FF ) THEN
      IF Get_TopView_Screen_Address THEN
         BEGIN

            IsTimeSharingActive := TRUE;

                                   (* Distinguish TaskView from TopView *)
            Regs.Ax := $1022;
            Regs.Bx := 0;
            INTR( $15 , Regs );

            IF ( Regs.Bx = 1 ) THEN
               MultiTasker         := TaskView
            ELSE
               MultiTasker         := DesqView;

            EXIT;

         END;
                                   (* Check for TaskView or TopView.  We do   *)
                                   (* a request for a TopView version number. *)
                                   (* If BX comes back $0001, this must be    *)
                                   (* TaskView.  Anything non-zero indicates  *)
                                   (* TopView or a compatible program.        *)
                                   (* Note:  This catches older TaskView      *)
                                   (*        versions which don't understand  *)
                                   (*        the DesqView call.               *)
   Regs.Ax := $1022;
   Regs.Bx := 0;
   INTR( $15 , Regs );

   IF ( Regs.Bx <> 0 ) THEN
      BEGIN

         IF ( Regs.Bx = 1 ) THEN
            MultiTasker         := TaskView
         ELSE
            MultiTasker         := TopView;

         IF ( NOT Get_TopView_Screen_Address ) THEN
            MultiTasker := Multitasker_None
         ELSE
            IsTimeSharingActive := TRUE;

      END;

END   (* IsTimeSharingActive *);

(*--------------------------------------------------------------------------*)
(*    TurnOnTimeSharing --- allow timesharing to proceed                    *)
(*--------------------------------------------------------------------------*)

PROCEDURE TurnOnTimeSharing;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*    Procedure:  TurnOnTimeSharing;                                        *)
(*                                                                          *)
(*    Purpose:    Activates timesharing                                     *)
(*                                                                          *)
(*    Calling Sequence:                                                     *)
(*                                                                          *)
(*       TurnOnTimeSharing;                                                 *)
(*                                                                          *)
(*    Calls:  MsDos                                                         *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   Regs : Registers;

BEGIN (* TurnOnTimeSharing *)

   CASE MultiTasker OF
                                   (* If DDos is active, $EB turns  *)
                                   (* on timesharing                *)
      DoubleDos:   BEGIN
                      Regs.Ax := $EB00;
                      MsDos( Regs );
                   END;

                                   (* Int 15H for TopView family products *)
      DesqView,
      TopView,
      MSWindows,
      TaskView:    BEGIN
                      Regs.Ax := $101C;
                      INTR( $15 , Regs );
                   END;

      ELSE;

   END (* CASE *);

END   (* TurnOnTimeSharing *);

(*--------------------------------------------------------------------------*)
(*        TurnOffTimeSharing --- suspend timesharing under DoubleDos        *)
(*--------------------------------------------------------------------------*)

PROCEDURE TurnOffTimeSharing;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*    Procedure:  TurnOffTimeSharing;                                       *)
(*                                                                          *)
(*    Purpose:    Suspends timesharing                                      *)
(*                                                                          *)
(*    Calling Sequence:                                                     *)
(*                                                                          *)
(*       TurnOffTimeSharing;                                                *)
(*                                                                          *)
(*    Calls:  MsDos                                                         *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   Regs : Registers;

BEGIN (* TurnOffTimeSharing *)

   CASE MultiTasker OF
                                   (* If DDos is active, $EA suspends *)
                                   (* timesharing                     *)
      DoubleDos:   BEGIN
                      Regs.Ax := $EA00;
                      MsDos( Regs );
                   END;
                                   (* Int 15H for TopView family products *)
      DesqView,
      TopView,
      MSWindows,
      TaskView:    BEGIN
                      Regs.Ax := $101B;
                      INTR( $15 , Regs );
                   END;

     ELSE;

   END (* CASE *);

END   (* TurnOffTimeSharing *);

(*--------------------------------------------------------------------------*)
(*            GiveUpTime --- gives away time slices to other task           *)
(*--------------------------------------------------------------------------*)

PROCEDURE GiveUpTime( NSlices : INTEGER );

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*    Procedure:  GiveUpTime;                                               *)
(*                                                                          *)
(*    Purpose:    Gives away time slices to other tasks                     *)
(*                                                                          *)
(*    Calling Sequence:                                                     *)
(*                                                                          *)
(*       GiveUpTime( NSlices :  INTEGER );                                  *)
(*                                                                          *)
(*          NSlices --- # of slices (55 ms) to give away, if DoubleDos.     *)
(*                                                                          *)
(*    Calls:  MsDos                                                         *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   Regs : Registers;

BEGIN (* GiveUpTime *)

   IF ( TimeSharingActive AND ( NSlices > 0 ) ) THEN
      CASE MultiTasker OF
                                   (* Function EE gives time to other part. *)
         DoubleDos:   BEGIN
                         Regs.Ah := $EE;
                         Regs.Al := NSlices;
                         MsDos( Regs );
                      END;

         DesqView,
         TopView,
         MSWindows,
         TaskView:    BEGIN
                         INLINE(
                                 $B8/$00/$10 { MOV     AX,$1000 ;Give up time}
                                 /$CD/$15    { INT     $15}
                               );
                      END;

         ELSE;

      END;

END   (* GiveUpTime *);

(*--------------------------------------------------------------------------*)
(*    Sync_Screen --- Synchronizes multitasker screen with hardware screen  *)
(*--------------------------------------------------------------------------*)

PROCEDURE Sync_Screen( S_Pos: INTEGER; NChars : INTEGER );

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*    Procedure:  Sync_Screen;                                              *)
(*                                                                          *)
(*    Purpose:    Synchronizes multitasker and hardware screens             *)
(*                                                                          *)
(*    Calling Sequence:                                                     *)
(*                                                                          *)
(*       Sync_Screen( S_Pos : INTEGER; NChars: INTEGER );                   *)
(*                                                                          *)
(*    Calls:  INTR                                                          *)
(*                                                                          *)
(*    Remarks:                                                              *)
(*                                                                          *)
(*       This facility is required by the TopView-family products.          *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

BEGIN (* Sync_Screen *)

   IF ( NChars > 0 ) THEN
      IF Write_Screen_Memory THEN
         IF ( MultiTasker = TopView ) THEN
            BEGIN

INLINE(
  $55/                      {         PUSH    BP                      ;Save BP in case of clobber}
  $C4/$3E/>DESQVIEW_SCREEN/ {         LES     DI,[>DesqView_Screen]   ;Pick up screen address}
  $8B/$8E/>NCHARS/          {         MOV     CX,[BP+>NChars]         ;Get update length in bytes}
  $8B/$86/>S_POS/           {         MOV     AX,[BP+>S_Pos]          ;Get offset of area to update}
  $01/$F8/                  {         ADD     AX,DI                   ;Add to offset of screen memory}
  $89/$C7/                  {         MOV     DI,AX                   ;Starting address of update}
  $B4/$FF/                  {         MOV     AH,$FF                  ;TopView synchronize screen}
  $CD/$10/                  {         INT     $10                     ;Video interrupt}
  $5D);                     {         POP     BP                      ;Restore BP}

            END;

END   (* Sync_Screen *);

(*--------------------------------------------------------------------------*)
(* Sync_Entire_Screen --- Synchronizes multitasker screen with hardware     *)
(*--------------------------------------------------------------------------*)

PROCEDURE Sync_Entire_Screen;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*    Procedure:  Sync_Entire_Screen;                                       *)
(*                                                                          *)
(*    Purpose:    Synchronizes multitasker and hardware screens             *)
(*                                                                          *)
(*    Calling Sequence:                                                     *)
(*                                                                          *)
(*       Sync_Entire_Screen;                                                *)
(*                                                                          *)
(*    Calls:  INTR                                                          *)
(*                                                                          *)
(*    Remarks:                                                              *)
(*                                                                          *)
(*       This facility is used by the TopView-family products when the      *)
(*       entire screen has been updated.                                    *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

BEGIN (* Sync_Entire_Screen *)

   IF Write_Screen_Memory THEN
      IF ( MultiTasker  = TopView ) THEN
         BEGIN

            INLINE(
  $55                       { PUSH    BP                    ;Save BP in case of clobber}
  /$C4/$3E/>DESQVIEW_SCREEN { LES     DI,[>DesqView_Screen] ;Pick up screen address}
  /$8B/$0E/>SCREEN_LENGTH   { MOV     CX,[>Screen_Length]   ;Get update length in bytes}
  /$D1/$E9                  { SHR     CX,1                  ;Update length in words}
  /$B4/$FF                  { MOV     AH,$FF                ;TopView synchronize screen}
  /$CD/$10                  { INT     $10                   ;Video interrupt}
  /$5D                      { POP     BP                    ;Restore BP}
                  );

         END;

END   (* Sync_Entire_Screen *);
