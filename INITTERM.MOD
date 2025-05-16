(*----------------------------------------------------------------------*)
(*                  InitTerm --- Initialize PibTerm                     *)
(*----------------------------------------------------------------------*)

PROCEDURE InitTerm;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  InitTerm                                             *)
(*                                                                      *)
(*     Purpose:    Initializes PibTerm                                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        InitTerm;                                                     *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        INt24On                                                       *)
(*        Set_Defaults                                                  *)
(*        InitOvly                                                      *)
(*        Read_Config_File                                              *)
(*        MyLoadOverlay                                                 *)
(*        TestVersionWarning                                            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I      : INTEGER;

BEGIN (* InitTerm *)
                                   (* Save top of heap for use  *)
                                   (* in DOS EXEC later on.     *)

   IF ( OFS( FreePtr^ ) = 0 ) THEN

                                   (* Free list is empty -- add *)
                                   (* $1000 to the segment.     *)

      HeapTop := PTR( SEG( FreePtr^ ) + $1000 , 0 )
   ELSE
      HeapTop := PTR( SEG( FreePtr^ ) + ( OFS( FreePtr^ ) SHR 4 ) , 0 );

                                   (* Don't allow <CTRL>Break   *)
                                   (* to zap program.           *)
   CheckBreak := FALSE;
                                   (* Make sure we have some    *)
                                   (* space on free list.       *)
   FreeMin := 8 * 100;
                                   (* Initialize critical error *)
                                   (* handler routine.          *)
   Int24ON;
                                   (* Initialize handler for    *)
                                   (* other errors.             *)
   ExitSave  := ExitProc;
   ExitProc  := @Error_Handler;
   HeapError := @Heap_Error_Handler;

                                   (* Display message if this is *)
                                   (* a test version.            *)
   IF Test_Version THEN
      Test_Version_Warning;
                                   (* Determine if multitasker active *)
                                   (* Also sets 'Multitasker' telling *)
                                   (* which multitasker is active     *)

   TimeSharingActive  := IsTimeSharingActive;

                                   (* Redirect keyboard input to *)
                                   (* PibTerm's special driver   *)
   Keyboard_Buffer := '';
                                   (* Get current interrupt 9 address *)

   GetIntVec( Kbd_Interrupt , Kbd_Save_Iaddr );

                                   (* Get current interrupt $10 address *)

   GetIntVec( Video_Interrupt , Video_Save_Iaddr );

                                   (* And initialize the global variables *)
   Set_Defaults;
                                   (* Read or create primary config. file *)

   IF ( NOT Read_Config_File ) THEN
      BEGIN
         Get_Default_Params( TRUE );
         Write_Config_File('');
      END;
                                   (* Allocate dialing directory, *)
                                   (* review buffer.              *)
   Allocate_Dial_And_Review;
                                   (* Read in directory, function keys, etc. *)
   Get_Other_Files;

                                   (* Set other parameters *)
   Set_Other_Parameters;
                                   (* Clear out command line area. *)

   Mem[PrefixSeg:$80] := 0;
   Mem[PrefixSeg:$81] := ORD( CR );

                                   (* Initialize communications *)
   Initialize_Communications;

END   (* InitTerm *);
