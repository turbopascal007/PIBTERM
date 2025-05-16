(*----------------------------------------------------------------------*)
(*           Exec_PC_Commands  --- Process EXEC PC BBS commands         *)
(*----------------------------------------------------------------------*)

PROCEDURE Exec_PC_Commands;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Exec_PC_Commands                                     *)
(*                                                                      *)
(*     Purpose:    Process Exec PC BBS special escape code commands     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Exec_PC_Commands;                                             *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Async_Send                                                    *)
(*        Async_Receive                                                 *)
(*        PibDownLoad                                                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   X:      INTEGER;
   Y:      INTEGER;
   Ch:     CHAR;
   L:      INTEGER;

(*----------------------------------------------------------------------*)

PROCEDURE Get_Async_Char;

VAR
   C: INTEGER;

BEGIN (* Get_Async_Char *)

   Async_Receive_With_TimeOut( 5 , C );

   IF ( C = TimeOut ) THEN
      Ch := #0
   ELSE
      Ch := CHR( C );

END   (* Get_Async_Char *);

(*----------------------------------------------------------------------*)

BEGIN (* Exec_PC_Commands *)

                                   (* Get next character after Exec PC flag *)
   Get_Async_Char;
                                   (* Handle it *)
   CASE Ch OF

      'D' : BEGIN (* Auto-Download *)

               FileName := '';
               L        := 0;

               WRITE('Autodownloading         ');

               REPEAT

                  Get_Async_Char;

                  IF NOT ( ORD( Ch ) IN [ACK,CAN,NUL] ) THEN
                     BEGIN
                        Async_Send( Ch );       (* echo 1 char at a time *)
                        FileName := FileName + Ch;
                        WRITE( Ch );
                     END;

               UNTIL ORD(Ch) IN [ACK,CAN];

               IF ORD( Ch ) = ACK THEN
                     BEGIN  (* Filename echoed correctly *)

                        FOR X := 0 TO 18 DO
                           WRITELN;

                        IF POS( '=X' , FileName ) <> 0 THEN
                           DELETE( FileName , POS( '=X' , FileName ) , 2 );

                        FileName := TRIM( FileName );

                        PibDownload( Xmodem_Chk );

                     END;

            END  (* Auto_DownLoad *);

      '2' : BEGIN  (* Draw a Box at corners (Oldx,Oldy) and (NewX,NewY) *)
               Draw_Box( OldX, OldY, NewX, NewY,
                         Global_Text_Attribute, Menu_Text_Color, '' );
            END;

      ELSE;

   END (* CASE *);

END   (* Exec_PC_Commands *);

