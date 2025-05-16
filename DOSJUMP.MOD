(*----------------------------------------------------------------------*)
(*   SetBlock --- Free up some memory above this program for DOS shell  *)
(*----------------------------------------------------------------------*)

FUNCTION SetBlock( VAR Paragraphs : WORD ) : BOOLEAN;

VAR
   Regs : Registers;

BEGIN (* SetBlock *)

   WITH Regs DO
      BEGIN
                                   (* Use DOS function $4A to release *)
                                   (* memory                          *)
         AH := $4A;
         ES := PrefixSeg;
         BX := Paragraphs;

         MSDOS( Regs );

         Paragraphs := BX;
         SetBlock   := ( NOT ODD( Flags ) );

      END;

END   (* SetBlock *);

(*----------------------------------------------------------------------*)
(*         DosExec -- Execute a DOS command or DOS shell                *)
(*----------------------------------------------------------------------*)

FUNCTION DosExec( Command : AnyStr ) : INTEGER;

VAR
   ComSpecStr     : AnyStr;
   OldHeapEnd     : POINTER;
   SizeOfFreeList : WORD;
   ParasToKeep    : WORD;
   ParasWeHave    : WORD;
   ParasForDos    : WORD;
   M              : WORD;

(*----------------------------------------------------------------------*)
(*   SubtractPointers -- Find # of bytes between two pointer addresses  *)
(*----------------------------------------------------------------------*)

FUNCTION SubtractPointers( High_Pointer : POINTER;
                           Low_Pointer  : POINTER ) : LONGINT;

BEGIN (* SubtractPointers *)

   SubtractPointers := ( LONGINT( SEG( High_Pointer^ ) ) SHL 4 +
                                  OFS( High_Pointer^ ) ) -
                       ( LONGINT( SEG( Low_Pointer^  ) ) SHL 4 +
                                  OFS( Low_Pointer^  ) );
END   (* SubtractPointers *);

(*----------------------------------------------------------------------*)
(*             HeapEnd --- Return pointer to end of heap                *)
(*----------------------------------------------------------------------*)

FUNCTION HeapEnd : POINTER;

BEGIN (* HeapEnd *)

   IF ( OFS( FreePtr^ ) = 0 ) THEN

                                   (* Free list is empty -- add *)
                                   (* $1000 to the segment.     *)

      HeapEnd := PTR( SEG( FreePtr^ ) + $1000 , 0 )
   ELSE
      HeapEnd := PTR( SEG( FreePtr^ ) + ( OFS( FreePtr^ ) SHR 4 ) , 0 );

END   (* HeapEnd *);

(*----------------------------------------------------------------------*)

BEGIN (* DosExec *)
                                   (* Calculate # bytes to save *)

   SizeOfFreeList := SubtractPointers( HeapTop , HeapEnd );

                                   (* Check for sufficient memory in *)
                                   (* unused file transfer buffer to *)
                                   (* save free list                 *)

   IF ( MaxSectorLength < LONGINT( SizeOfFreeList ) ) THEN
      BEGIN
                                   (* Not enough memory to store free list *)
        DosExec := -1;
        EXIT;
      END;
                                   (* Save current pointer to end of *)
                                   (* free list                      *)
   OldHeapEnd  := HeapEnd;
                                   (* Get current DOS memory allocation *)
                                   (* from memory control block         *)

   ParasWeHave := MemW[ PRED( PrefixSeg ) : 3 ];

                                   (* Calculate amount of memory to give up *)

   ParasForDos := PRED( SubtractPointers( HeapTop , HeapPtr ) SHR 4 );

                                   (* Calculate amount of memory to keep *)
                                   (* while in shell                     *)

   ParasToKeep := ParasWeHave - ParasForDos;

                                  (* See if enough memory to run DOS *)

   IF ( ( ParasForDos > 0 ) AND
        ( ParasForDos < ( MinSpaceForDos SHR 4 ) ) ) THEN
      BEGIN
         DosExec := -4;
         EXIT;
      END;
                                   (* Deallocate memory for DOS *)

   IF ( NOT SetBlock( ParasToKeep ) ) THEN
      BEGIN
         DosExec := -2;
         EXIT;
      END;
                                   (* Build the Command string *)

   ComSpecStr := GetEnvStr( 'COMSPEC' );

   IF ( LENGTH( Command ) > 0 ) THEN
      Command := '/C ' + Command;

   M := ( ParasForDos - 240 ) SHR 6;
   WRITELN('Approximate memory available: ', M, 'K');

                                   (* Save free list *)

   MOVE( OldHeapEnd^, Sector_Data, SizeOfFreeList );

                                   (* Call Turbo's EXEC function *)
   EXEC( ComSpecStr , Command );
                                   (* Reallocate memory from DOS *)

   IF ( NOT SetBlock( ParasWeHave ) ) THEN
      BEGIN
         DosExec := -3;
         EXIT;
      END;
                                   (* Restore free list *)

   MOVE( Sector_Data, OldHeapEnd^, SizeOfFreeList );

                                   (* Function result is in DosError *)
   DosExec := DosError;

END   (* DosExec *);

(*----------------------------------------------------------------------*)
(*                   DosJump --- Jump to Dos                            *)
(*----------------------------------------------------------------------*)

PROCEDURE DosJump( Dos_String : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  DosJump;                                             *)
(*                                                                      *)
(*     Purpose:    Provides facility for jumping to DOS                 *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        DosJump( Dos_String : AnyStr );                               *)
(*                                                                      *)
(*           Dos_String --- DOS command to execute                      *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        DosExec                                                       *)
(*        Open_For_Append                                               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I            : INTEGER;
   Ierr         : INTEGER;
   Local_Save   : Saved_Screen_Ptr;
   Open_Flag    : BOOLEAN;
   Save_Cursor  : INTEGER;
   Save_Status  : BOOLEAN;
   Save_Video   : BOOLEAN;
   Save_Border  : INTEGER;
   Save_VidMode : INTEGER;
   Save_Int1B   : POINTER;

BEGIN (* DosJump *)
                                   (* Save screen contents. Note that *)
                                   (* EGA contents must actually be   *)
                                   (* saved this time.                *)
{
   Really_Save_EGA := TRUE;
}
   Save_Screen( Local_Save );

   Save_VidMode := Current_Video_Mode;

   PibTerm_Window( 1, 1, Max_Screen_Col, Max_Screen_Line );
   Scroll( 1, Max_Screen_Line, 1, Max_Screen_Col, 0,
           LightGray, Black );
   Save_Border := Global_Border_Color;
   Set_Border_Color( Black );
   GoToXY( 1 , 1 );

   Save_Status    := Do_Status_Time;
   Do_Status_Time := FALSE;

   IF ( LENGTH( Dos_String ) = 0 ) THEN
      BEGIN
         WRITELN;
         WRITELN('Jump to DOS:  Enter EXIT to return to PibTerm');
      END;
                                   (* Turn off extended keypad *)
   IF Extended_Keypad THEN
      Remove_Keyboard_Handler;
                                   (* Turn off video handler   *)

   Save_Video := Video_Handler_Installed;

   IF Save_Video THEN
      Remove_Video_Handler;
                                   (* Close capture file *)
   IF Capture_On THEN
         (*!I-*)
      CLOSE( Capture_File );
         (*!I+*)
                                   (* Close log file *)
   IF Log_File_Open THEN
         (*!I-*)
      CLOSE( Log_File );
         (*!I+*)

   I := Int24Result;
                                   (* Remove Int 24 error handler *)
   Int24OFF( FALSE );
                                   (* Close communications if requested *)
   IF Close_Comm_For_Dos THEN
      Async_Close( FALSE );
                                   (* Change cursor to block *)

   IF ( Font8x8Loaded OR ( Current_Video_Mode <> 7 ) ) THEN
      CursorSet( $0107 )
   ELSE
      CursorSet( $010D );
                                   (* Allow <CTRL>Break checking *)
   GetIntVec( $1B , Save_Int1B );
   SetIntVec( $1B , SaveInt1B  );

                                   (* Jump to DOS *)
   Ierr := DosExec( Dos_String );

                                   (* Disallow <CTRL>Break checking *)
   SetIntVec( $1B , Save_Int1B );

                                   (* Restore previous video mode *)

   IF ( Current_Video_Mode <> Save_VidMode ) THEN
      Set_Text_Mode( Save_VidMode );

                                   (* Reset EGA if needed         *)
   IF EGA_Present THEN
      Set_EGA_Text_Mode( Max_Screen_Line );

                                   (* Change cursor back to underline *)
   CursorOn;
                                   (* Restore Int24 Error handler *)
   Int24ON;
                                   (* Restore communications.  Port *)
                                   (* opened twice in case major    *)
                                   (* weirdness causes first open   *)
                                   (* to screw up.                  *)
   IF Close_Comm_For_Dos THEN
      FOR I := 1 TO 2 DO
         Open_Flag  := Async_Open( Comm_Port, Baud_Rate, Parity, Data_Bits,
                                   Stop_Bits )
   ELSE
      Async_Clear_Errors;

   CASE Ierr OF
      -1: WRITELN('Not enough memory to store free list, DOS jump cannot be done');
      -2: WRITELN('Set Block error, DOS jump cannot be done');
      -3: BEGIN
{
             WRITELN('Set Block error on return from DOS, PibTerm cannot continue.');
             WRITELN('You will probably need to re-boot.');
}
             Halt( BadDosJump );
          END;
      -4: WRITELN('Not enough memory to jump to DOS');
      ELSE
         WRITELN('Back to PibTerm, DOS return code is ',Ierr);
   END (* CASE *);
                                   (* Reopen capture file for append *)
   IF Capture_On THEN
      BEGIN

         IF ( NOT Open_For_Append( Capture_File , Capture_File_Name , I ) ) THEN
            BEGIN
               WRITELN('Can''t re-open capture file ',
                        Capture_File_Name);
               WRITELN('Capture option TURNED OFF.');
               Capture_On := FALSE;
               Window_Delay;
            END;

      END;
                                   (* Reopen log file for append *)
   IF Logging_On THEN
      Log_File_Open := Open_For_Append( Log_File,
                                        Log_File_Name, I );

                                   (* Log this jump to DOS *)

   Write_Log('Jump to DOS   : ' + Dos_String, FALSE, FALSE );
   Write_Log('   Return Code: ' + IToS( Ierr ), TRUE, FALSE );

                                   (* If we got here from Alt-J,  *)
                                   (* or request for shell in     *)
                                   (* script, then wait for a key *)
                                   (* to be struck.               *)
{
   IF ( LENGTH( Dos_String ) = 0 ) OR
      ( ( ( Err <> 0 ) OR ( Ierr <> 0 ) ) AND Attended_Mode ) AND
      ( NOT Host_Mode ) THEN
      Press_Any;
}
                                   (* Restore screen contents *)

   Restore_Screen_And_Colors( Local_Save );

   Set_Border_Color( Save_Border );

                                   (* Restore status line updating *)
   Do_Status_Time := Save_Status;
                                   (* Restore extended keyboard    *)
   IF Extended_Keypad THEN
      Install_Keyboard_Handler;
                                   (* Restore video handler        *)
   IF Save_Video THEN
      Install_Video_Handler;
                                   (* Turn off save EGA flag       *)
{
   Really_Save_EGA := FALSE;
}
END   (* DosJump *);
