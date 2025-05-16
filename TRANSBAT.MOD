(*----------------------------------------------------------------------*)
(*  Transfer_Through_Batch_File --- Transfer file using batch file      *)
(*----------------------------------------------------------------------*)

PROCEDURE Transfer_Through_Batch_File( Transfer_Protocol : Transfer_Type;
                                       TName             : String12;
                                       Direc             : CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Transfer_Through_Batch_File                          *)
(*                                                                      *)
(*     Purpose:    Sends or receives file using transfer protocol       *)
(*                 defined in batch file.                               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Transfer_Through_Batch_File( Transfer_Protocol: Transfer_Type;*)
(*                                     TName            : String12;     *)
(*                                     Direc            : CHAR );       *)
(*                                                                      *)
(*           Transfer_Protocol --- Transfer protocol used               *)
(*           TName --- The name of the batch file to be used.           *)
(*           Direc --- 'S' if sending file, 'R' if receiving file.      *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        Parameters passed to batch file:                              *)
(*                                                                      *)
(*           %1 = comm port number                                      *)
(*           %2 = baud rate                                             *)
(*           %3 = parity                                                *)
(*           %4 = data bits                                             *)
(*           %5 = directory to send files from/receive files to         *)
(*           %6 = file spec of files to send/receive                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   S_Baud_Rate   : STRING[6];
   S_Port        : STRING[3];
   S_BlockSize   : STRING[6];
   S_Data_Bits   : STRING[2];
   Cur_Path      : FileStr;
   S_Trans_Dir   : FileStr;
   L_Trans_Dir   : INTEGER;
   Trans_Str     : AnyStr;
   Save_Close    : BOOLEAN;
   Err           : INTEGER;
   Direction     : STRING[10];

BEGIN (* Transfer_Through_Batch_File *)

                                   (* Get comm port data *)

   STR( Baud_Rate:6 , S_Baud_Rate );
   STR( Comm_Port:3 , S_Port      );
   STR( Data_Bits:2 , S_Data_Bits );

                                   (* Remember current drive/directory *)
   GetDir( 0 , Cur_Path );
   Err := INT24Result;
                                   (* Get transfer directory *)
   IF ( Direc = 'S' ) THEN
      BEGIN
         IF Host_Mode THEN
            S_Trans_Dir    := Host_Mode_Download
         ELSE
            S_Trans_Dir    := '';
         Direction := ' send: ';
      END
   ELSE
      BEGIN
         IF Host_Mode THEN
            S_Trans_Dir := Host_Mode_Upload
         ELSE
            S_Trans_Dir := Download_Dir_Path;
         Direction := ' receive: ';
      END;
                                   (* If directory name is null, *)
                                   (* make it current directory. *)
   IF ( S_Trans_Dir = '' ) THEN
      S_Trans_Dir := Cur_Path;
                                   (* Remove trailing slash *)

   L_Trans_Dir := LENGTH( S_Trans_Dir );

   IF ( S_Trans_Dir[L_Trans_Dir] = '\' ) THEN
      BEGIN
         DELETE( S_Trans_Dir, L_Trans_Dir, 1 );
         DEC   ( L_Trans_Dir );
      END;
                                   (* Build batch file invocation *)

   Trans_Str := TRIM( TName         +
                      S_Port        +
                      S_Baud_Rate   + ' ' +
                      Parity        +
                      S_Data_Bits   + ' ' +
                      S_Trans_Dir   + ' ' +
                      FileName );

   Save_Close         := Close_Comm_For_Dos;
   Close_Comm_For_Dos := TRUE;

   Write_Log( LTrim( Transfer_Name_List[SUCC(ORD(Transfer_Protocol))] ) +
              Direction + Trans_Str, FALSE, TRUE );

                                   (* Move to transfer directory *)

   IF ( L_Trans_Dir > 0 ) THEN
      BEGIN
         ChDir( S_Trans_Dir );
         Err := INT24Result;
      END;
                                   (* Invoke batch file *)
   DosJump( Trans_Str );

   Close_Comm_For_Dos := Save_Close;

                                   (* Restore current drive/directory *)
   IF ( L_Trans_Dir > 0 ) THEN
      BEGIN
         ChDir( Cur_Path );
         Err := INT24Result;
      END;

END   (* Transfer_Through_Batch_File *);
