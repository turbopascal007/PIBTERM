(*----------------------------------------------------------------------*)
(*      Set_Status_Line_Name --- Sets terminal name in status line      *)
(*----------------------------------------------------------------------*)

PROCEDURE Set_Status_Line_Name( Name : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Set_Status_Line_Name                                 *)
(*                                                                      *)
(*     Purpose:    Sets status line entries                             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Set_Status_Line_Name( Name : AnyStr );                        *)
(*                                                                      *)
(*           Name --- the terminal name                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I       : INTEGER;
   L       : INTEGER;
   S       : AnyStr;
   M_String: STRING[2];
   H_String: STRING[2];
   Hours   : INTEGER;
   Mins    : INTEGER;
   ScrName : STRING[10];

(* STRUCTURED *) CONST

   OffOn : ARRAY[0..1] OF CHAR  = ('-','+');

   Status_Line_Skeleton : STRING[34] = 'CA  PR  LO  LF  LE  XO  CT  CD COM';

(*
             1         2         3         4         5         6
    12345678901234567890123456789012345678901234567890123456789012345
     TTTTTTTTTT HH:MM -CA -PR -LO -LF -LE -XO -CT -CD COM2 19200N81
*)
   XOFF_Message : STRING[13] = 'XOFF received';

BEGIN (* Set_Status_Line_Name *)

   Status_Line_Name := Dupl( ' ' , 19 ) + Status_Line_Skeleton +
                       Dupl( ' ' , Max_Screen_Col - 53 );

   IF Script_File_Mode THEN
      BEGIN
         Status_Line_Name[1] := '+';
         ScrName             := Scripts[Current_Script_Num].Script_Name;
         IF ( ScrName[1] = '!' ) THEN
            I := 1
         ELSE
            I := 2;
         MOVE( ScrName[1], Status_Line_Name[I], LENGTH( ScrName ) );
      END
   ELSE IF Script_Learn_Mode THEN
      BEGIN
         Status_Line_Name[1] := '-';
         ScrName             := Script_File_Name;
         MOVE( ScrName[1], Status_Line_Name[2], LENGTH( ScrName ) );
      END
   ELSE
      MOVE( Short_Terminal_Name[1] , Status_Line_Name[2],
            LENGTH( Short_Terminal_Name ) );

   IF Async_XOff_Received THEN
      MOVE( XOFF_Message[1], Status_Line_Name[65], 13 );

   Status_Line_Name[19] := OffOn[ ORD( Capture_On ) ];
   Status_Line_Name[23] := OffOn[ ORD( Printer_On ) ];
   Status_Line_Name[27] := OffOn[ ORD( Logging_On ) ];
   Status_Line_Name[31] := OffOn[ ORD( Add_LF ) ];
   Status_Line_Name[35] := OffOn[ ORD( Local_Echo ) ];
   Status_Line_Name[39] := OffOn[ ORD( Async_Do_XonXoff ) ];
   Status_Line_Name[43] := OffOn[ ORD( Async_Do_CTS ) ];
   Status_Line_Name[47] := OffOn[ ORD( Current_Carrier_Status ) ];

   Status_Line_Name[54] := CHR( ORD('0') + Comm_Port );

   STR( Baud_Rate:5, S );
   S := S + Parity + CHR( ORD('0') + Data_Bits ) + CHR( ORD('0') + Stop_Bits );

   MOVE( S[1], Status_Line_Name[56], ORD( S[0] ) );

   IF Do_Status_Time THEN
      BEGIN
         Current_Status_Time := -1;
         Update_Status_Line;
      END;

END   (* Set_Status_Line_Name *);

