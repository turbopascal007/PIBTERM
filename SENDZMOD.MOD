(*----------------------------------------------------------------------*)
(*        Send_Zmodem_File --- Uploads file with Zmodem                 *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Zmodem_File( Transfer_Protocol : Transfer_Type );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Send_Zmodem_File                                     *)
(*                                                                      *)
(*     Purpose:    Uploads files using Zmodem                           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Send_Zmodem_File( Transfer_Protocol : Transfer_Type );        *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   S_Baud_Rate   : STRING[6];
   S_Port        : STRING[3];
   S_BlockSize   : STRING[6];
   Send_Str      : AnyStr;
   Save_Close    : BOOLEAN;

BEGIN (* Send_Zmodem_File *)

   STR( Baud_Rate:6     , S_Baud_Rate );
   STR( Comm_Port:3     , S_Port      );

   IF ( Transfer_Protocol = Zmodem ) THEN
      STR( Zmodem_BlockSize, S_BlockSize )
   ELSE
      S_BlockSize := ' ';

   Send_Str := 'SENDZMOD' + S_Port +
               S_Baud_Rate + ' ' +
               DSZ_Send_Names[ Transfer_Protocol ] +
               ' ' + FileName +
               ' ' + S_BlockSize;

   Save_Close         := Close_Comm_For_Dos;
   Close_Comm_For_Dos := TRUE;

   Write_Log( 'Zmodem invocation: ' + Send_Str, FALSE, FALSE );

   DosJump( Send_Str );

   Close_Comm_For_Dos := Save_Close;

END   (* Send_Zmodem_File *);
