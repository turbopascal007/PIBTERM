(*----------------------------------------------------------------------*)
(*         Open_For_Append --- Open text file for appending to end      *)
(*----------------------------------------------------------------------*)

FUNCTION Open_For_Append( VAR F      : Text_File;
                              F_Name : AnyStr   ;
                          VAR Error  : INTEGER   ) : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Open_For_Append                                      *)
(*                                                                      *)
(*     Purpose:    Opens text file for append                           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Open_OK := Open_For_Append( VAR F      : Text_File;           *)
(*                                        F_Name : AnyStr   ;           *)
(*                                    VAR Error  : INTEGER ) : BOOLEAN; *)
(*                                                                      *)
(*           F      --- Text file to be opened                          *)
(*           F_Name --- File name of text file                          *)
(*           Error  --- I/O error encountered here                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Open_Ok : BOOLEAN;
   F_Byte  : FILE OF BYTE;

BEGIN (* Open_For_Append *)
                                   (* See if file exists or is empty.  *)
                                   (* File of byte req'd for filesize. *)
   ASSIGN( F_Byte , F_Name );
   RESET( F_Byte );

   Error   := Int24Result;
   Open_OK := ( Error = 0 );
                                   (* If file exists, but is empty, *)
                                   (* use REWRITE to avoid error.   *)
   IF Open_OK THEN
      IF ( FileSize( F_Byte ) = 0 ) THEN
         Open_OK := FALSE;

   CLOSE( F_Byte );
   Error := Int24Result;
                                   (* Now open file as text file. *)
   ASSIGN( F , F_Name );

   IF Open_OK THEN
      APPEND( F )
   ELSE
      REWRITE( F );

   Error           := Int24Result;
   Open_For_Append := ( Error = 0 );

END   (* Open_For_Append *);
