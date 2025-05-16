(*----------------------------------------------------------------------*)
(*           View_A_File --- List ascii file                            *)
(*----------------------------------------------------------------------*)

PROCEDURE View_A_File( View_File_Name : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  View_A_File                                          *)
(*                                                                      *)
(*     Purpose:    Lists selected ascii file                            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        View_A_File;                                                  *)
(*                                                                      *)
(*     Calls:   View_Prompt                                             *)
(*              Save_Screen                                             *)
(*              Restore_Screen                                          *)
(*              Draw_Menu_Frame                                         *)
(*              Reset_Global_Colors                                     *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine will list non-ascii files, but they will be      *)
(*        meaningless.                                                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Save_Do_Status_Time : BOOLEAN;
   View_File_Open      : BOOLEAN;
   View_File_Size      : LONGINT;
   Screen_Size         : INTEGER;
   Name_Given          : BOOLEAN;

BEGIN (* View_A_File *)
                                   (* No status time updates here *)

   Save_Do_Status_Time := Do_Status_Time;
   Do_Status_Time      := FALSE;
   Screen_Size         := Max_Screen_Line - 2;
   Name_Given          := ( LENGTH( View_File_Name ) > 0 );

                                   (*  Draw view menu *)
   Save_Screen( Saved_Screen );
   Draw_Menu_Frame( 5, 10, 75, 16, Menu_Frame_Color,
                    Menu_Title_Color, Menu_Text_Color, 'View A File' );

                                   (* Get name of file to list *)
   TextColor( Menu_Text_Color_2 );
   WRITELN;
   WRITELN('Enter name of file to view: ');
   WRITE  ('>');
   TextColor( Menu_Text_Color );
   IF Name_Given THEN
      WRITE( View_File_Name )
   ELSE
      Read_Edited_String( View_File_Name );
   WRITELN;

   TextColor( Menu_Text_Color_2 );

   View_File_Open := FALSE;
                                   (* Ensure file exists ... *)

   IF LENGTH( View_File_Name ) > 0 THEN
      BEGIN  (* View_File_Name > 0 *)

         View_File_Size := Get_File_Size( View_File_Name , View_File_Open );

         IF ( NOT View_File_Open ) THEN
            BEGIN (* Int24Result <> 0 *)
               WRITELN('Can''t open file ',View_File_Name,' for viewing.');
               Press_Any;
            END   (* Int24Result <> 0 *)

                                   (* ... and file is not empty *)

        ELSE IF ( View_File_Size <= 0  ) THEN
            BEGIN  (* File is empty *)
               WRITELN('File ',View_File_Name,' is empty.');
               Press_Any;
               View_File_Open := FALSE;
            END    (* File is empty *)

        ELSE                       (* List the file *)

           List_One_File( View_File_Name );

      END  (* View_File_Name > 0 *);

                                   (* Restore previous screen *)

   Restore_Screen_And_Colors( Saved_Screen );

   Do_Status_Time := Save_Do_Status_Time;

END   (* View_A_File *);
