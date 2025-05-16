(*$M 25000,0,655360*)
PROGRAM PibTerm;

(*----------------------------------------------------------------------*)
(*               PibTerm --- Terminal Emulator in Turbo Pascal          *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  Author:   (c) 1985, 1986, 1987 by Philip R. Burns                   *)
(*                                                                      *)
(*  Date:     January, 1987                                             *)
(*  Version:  1.0  (January, 1985)                                      *)
(*            2.0  (July, 1985)                                         *)
(*            3.0  (October, 1985)                                      *)
(*            3.2  (November, 1985)                                     *)
(*            4.0  (September, 1987)                                    *)
(*            4.1  (December, 1987)                                     *)
(*                                                                      *)
(*  Systems:  For MS-DOS on IBM PCs and close compatibles only.         *)
(*            Note:  I have checked these on under MSDOS 2.x/3.x        *)
(*                   on a variety of IBM PCs and clones.                *)
(*                                                                      *)
(*  Overview: This program provides a comprehensive terminal emulation  *)
(*            and remote communications facility.  PibTerm emulates     *)
(*            several different terminals.                              *)
(*                                                                      *)
(*            PibTerm allows for file transfer facilities using         *)
(*            many different protocols.                                 *)
(*                                                                      *)
(*            The commands and general program use follow that of other *)
(*            popular communications programs like PC-Talk and Qmodem.  *)
(*                                                                      *)
(*            PibTerm also provides a simple host communications        *)
(*            facility like a mini-BBS.                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*                            Restriction                               *)
(*                            -----------                               *)
(*                                                                      *)
(*           You may use this code only for NON COMMERCIAL purposes     *)
(*           unless you explicitly obtain my permission.  I take a dim  *)
(*           view of others making money on my work and those of other  *)
(*           people whose code I've inserted here.                      *)
(*                                                                      *)
(*           Please feel free to add new features.  I wrote this        *)
(*           program to give people a useful and usable basic terminal  *)
(*           facility, and to show how Turbo Pascal can be used for     *)
(*           asynchronous communications, menu display, windowing, and  *)
(*           so on.  I hope that you find this program useful -- and,   *)
(*           if you expand upon it, please upload your extensions so    *)
(*           that all of us can enjoy them!                             *)
(*                                                                      *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*           Suggestions for improvements or corrections are welcome.   *)
(*           Please leave messages on Gene Plantz's BBS (312) 882 4145  *)
(*           or Ron Fox's BBS (312) 940 6496.                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

USES
   PT4PATCH,  OverMgr,  Dos,      Crt,      GlobType,
   StringMan, GlobRout, PibTimer, PibMTask, PibAsync,
   PT4DIAL,   PT4EDIT,  PT4UTIL,  PT4VIEW,
   PT4ASCI,   PT4CISB,  PT4DISPC, PT4KERM,  PT4XMOD,
   PT4UPDWN,  PT4TERM,  PT4SETP,  PT4SCRI,  PT4INIT,
   PT4GENRT,  PT4ANSI,  PT4GOSSI, PT4T4010, PT4HOST;

                                   (* Initialize PibTerm interface      *)
{$I INITTERM.MOD }

(*----------------------------------------------------------------------*)

PROCEDURE Terminal_Emulations;

(* STRUCTURED *) CONST
   PibTerm_Stops : STRING[18] = '*** PibTerm stops.';

(*----------------------------------------------------------------------*)

PROCEDURE Load_User_Terminal;

VAR
   User_Number : INTEGER;

BEGIN (* Load_User_Terminal *)

   User_Number := SUCC( ORD( Terminal_To_Emulate ) - ORD( User1 ) );

   IF ( POS( '.CHN', UpperCase( User_Term_Name[User_Number] ) ) > 0 ) THEN
      Emulate_User_Terminal
   ELSE
      Emulate_General_Terminal;

END   (* Load_User_Terminal *);

(*----------------------------------------------------------------------*)

BEGIN (* Terminal_Emulations *)

   REPEAT

      Gossip_Mode_On := ( Terminal_To_Emulate = Gossip );

      CASE Terminal_To_Emulate OF

         Ansi         : Emulate_Ansi( FALSE );

         VT100        : Emulate_Ansi( TRUE );

         VT52,
         ADM3a,
         ADM5,
         TV925,
         Dumb         : Emulate_General_Terminal;

         Gossip       : Emulate_Gossip;

         HostMode     : Emulate_Host;

         User1..User5 : Load_User_Terminal;

         TEK4010      : Emulate_TEK4010;

         ELSE;

      END (* CASE *);

   UNTIL ( PibTerm_Done );

END   (* Terminal_Emulations *);

(* ------------------------------------------------------------------------ *)
(*                  PibTerm  --- Main Program                               *)
(* ------------------------------------------------------------------------ *)

BEGIN (* PibTerm  *)
                                   (* Initialize PibTerm              *)
   InitTerm;
                                   (* Begin Terminal Emulation        *)
   REPEAT
      Terminal_Emulations;
   UNTIL ( PibTerm_Done );
                                   (* Rewrite dialing directory       *)
                                   (* if necessary                    *)
   IF Any_Dialing_Changes THEN
      BEGIN
         Set_Text_Mode( Text_Mode );
         Rewrite_Dialing_Directory;
      END;
                                   (* Clean up and terminate          *)
   FiniTerm;
                                   (* Clear screen unless error       *)

   IF ( NOT Error_Exit_Taken ) THEN
      BEGIN
         Window( 1, 1, Max_Screen_Col, Max_Screen_Line );
         Scroll( 1, Max_Screen_Line, 1, Max_Screen_Col, 0,
                 LightGray, Black );
         GoToXY( 1 , 1 );
      END;

END   (* PibTerm  *).
