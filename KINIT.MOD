(*----------------------------------------------------------------------*)
(*              Kermit_Init --- Initialize global Kermit variables      *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Init;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Kermit_Init                                          *)
(*                                                                      *)
(*     Purpose:    Initializes global Kermit variables                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Kermit_Init;                                                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I: INTEGER;

BEGIN (* Kermit_Init *)
                                   (* Ascii is default if not given *)

   IF Kermit_File_Type_Var = Kermit_None THEN
      Kermit_File_Type_Var := Kermit_Ascii;

                                   (* Default checksum method *)

   His_Chk_Type         := Kermit_Chk_Type;

                                   (* Initial packet size *)

   Kermit_Packet_Size   := Kermit_Init_Packet_Size;

                                   (* Set padding *)
   My_Pad_Num    := 0;
   My_Pad_Char   := Kermit_Pad_Char;

                                   (* Send a CR to start with *)

   Send_EOL      := ORD( Kermit_EOL );

                                   (* No 8-bit quoting unless binary with parity *)
   Quoting       := FALSE;
                                   (* Time out *)
   His_TimeOut   := Kermit_TimeOut;

                                   (* 8-bit quote *)

   His_Quote_8_Char   := Kermit_Quote_8_Char;

                                   (* Repeating data off by default *)
   His_Repeat_Char    := ' ';
   Repeating          := FALSE;
                                   (* Not logging out server *)
   Logging_Out_Server := FALSE;
                                   (* Display always on by default *)
   Display_Status     := TRUE;
                                   (* Assume no attributes         *)
   Kermit_Attributes  := FALSE;
                                   (* Default window size          *)

   His_Kermit_Window_Size := Kermit_Window_Size;

                                   (* Defaults for long packets    *)

   His_Kermit_MaxLX1 := Kermit_Extended_Block DIV 95;
   His_Kermit_MaxLX2 := Kermit_Extended_Block MOD 95;

                                   (* Set capabilities *)
   Kermit_Do_Long_Blocks := FALSE;
   Kermit_Do_Sliding_Win := FALSE;

                                   (* Turn off attributes *)
   Kermit_Do_File_Size   := FALSE;
   Kermit_Do_File_Time   := FALSE;
   Kermit_Do_File_Date   := FALSE;

   Kermit_File_Date      := 0;
   Kermit_File_Time      := 0;
   Kermit_File_Size      := 0;
   Kermit_Window_Top     := 0;
   Kermit_Window_Bottom  := 0;

   Kermit_Doing_Transfer := FALSE;

END   (* Kermit_Init *);
