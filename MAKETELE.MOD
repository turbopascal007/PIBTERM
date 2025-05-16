(*----------------------------------------------------------------------*)
(*          Make_Telink_Header --- Send special TELINK header block     *)
(*----------------------------------------------------------------------*)

PROCEDURE Make_Telink_Header( File_Entry : SearchRec );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*       Procedure:  Make_Telink_Header                                 *)
(*                                                                      *)
(*       Purpose:    Makes special TELINK header block                  *)
(*                                                                      *)
(*       Calling sequence:                                              *)
(*                                                                      *)
(*          Make_Telink_Header( File_Entry : SearchRec );               *)
(*                                                                      *)
(*       Calls:  None                                                   *)
(*                                                                      *)
(*       Remarks:                                                       *)
(*                                                                      *)
(*          The Telink header block is ALWAYS sent in Checksum mode,    *)
(*          regardless of whether or not the files are to be sent in    *)
(*          CRC or checksum mode.                                       *)
(*                                                                      *)
(*          Format of Telink/SeaLink block 0:                           *)
(*                                                                      *)
(*             Bytes         Contents                                   *)
(*             -----       ---------------------------------------      *)
(*                                                                      *)
(*               1           SYN (SOH for SeaLink)                      *)
(*               2             0                                        *)
(*               3           255                                        *)
(*              4-7          File size in MS DOS directory form         *)
(*              8-9          Creation date in MS DOS form               *)
(*             10-11         Creation time in MS DOS form               *)
(*             12-27         Name of file in 'name.ext' form            *)
(*              28           Version number (always zero here)          *)
(*             29-44         PIBTERM  -- sending program's name         *)
(*             45-131        All zeroes                                 *)
(*              132          Checksum of block                          *)
(*                                                                      *)
(*          The first three bytes and the checksum are added later by   *)
(*          the Xmodem send routine.  The rest are constructed here.    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I            : INTEGER;
   J            : INTEGER;
   L            : INTEGER;
   CheckSum     : INTEGER;
   ACK_Ok       : BOOLEAN;
   Int_Ch       : INTEGER;
   C            : STRING[1];

BEGIN (* Make_Telink_Header *)
                                   (* Zero out block *)
   FOR I := 1 TO 130 DO
      Sector_Data[I] := 0;
                                   (* File size in 32-bit MS DOS form *)

   MOVE( File_Entry.Size , Sector_Data[1], 4 );

                                   (* Creation time/date in MS DOS form *)

   MOVE( File_Entry.Time , Sector_Data[5], 4 );

                                   (* File name *)
   L := LENGTH( File_Entry.Name );

   FOR J := 1 TO L DO
      Sector_Data[J+8] := ORD( File_Entry.Name[J] );

   FOR I := L TO 16 DO
      Sector_Data[I+8] := ORD(' ');

                                   (* Sending program's name *)
   FOR I := 1 TO 16 DO
      BEGIN
         C                 := COPY( 'PIBTERM         ', I, 1 );
         Sector_Data[I+25] := ORD( C[1] );
      END;

END   (* Make_Telink_Header *);
