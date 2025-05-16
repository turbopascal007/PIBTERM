PROCEDURE Emulate_Host;

(*----------------------------------------------------------------------*)
(*               PibHost --- Host mode (mini-BBS) for PibTerm           *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  Author:   Philip R. Burns                                           *)
(*  Date:     February, 1986                                            *)
(*  Version:  1.0  (July, 1985)                                         *)
(*            1.1  (July, 1985)                                         *)
(*            1.2  (August, 1985)                                       *)
(*            2.0  (August, 1985)                                       *)
(*            3.0  (October, 1985)                                      *)
(*            3.2  (November, 1985)                                     *)
(*            4.0  (June, 1987)                                         *)
(*            4.1  (December, 1987)                                     *)
(*                                                                      *)
(*  Systems:  For MS-DOS on IBM PCs and close compatibles only.         *)
(*            Note:  I have checked these on Zenith 151s under          *)
(*                   MSDOS 2.1 and IBM PCs under PCDOS 2.0.             *)
(*                                                                      *)
(*  Overview: This overlay provides a simple host mode for use with     *)
(*            PibTerm.  Facilities are provided for message leaving     *)
(*            and file transfer.  This code can be used as a very       *)
(*            simple remote bulletin board.  However, it lacks the      *)
(*            security provisions needed for a genuine BBS, and is      *)
(*            really intended to cover the need for a simple remote     *)
(*            facility for a small private group of users.              *)
(*                                                                      *)
(*            Beginning with version 4.0, it is also possible for       *)
(*            designated users to jump to DOS and thus run DOS commands *)
(*            from the remote system.                                   *)
(*                                                                      *)
(*  Use:      This code assumes a Hayes-compatible modem.  You may need *)
(*            to modify the code if your modem doesn't return verbal    *)
(*            codes sufficient to determine the baud rate of the caller.*)
(*            The modem is assumed to be set to answer the phone        *)
(*            automatically.                                            *)
(*                                                                      *)
(*            To invoke host mode after entering PibTerm, enter Alt-W.  *)
(*                                                                      *)
(*            If you want the remote session echoed to the printer or   *)
(*            captured to disk, then use the Alt-L and Alt-O commands   *)
(*            before using Alt-W to invoke host mode.                   *)
(*                                                                      *)
(*            The following files are required above those normally     *)
(*            used with PibTerm:                                        *)
(*                                                                      *)
(*              PIBTERM.USF  --- the user file.  A simple text file     *)
(*                               containing the first name, last name,  *)
(*                               and password for each authorized user. *)
(*                               This file can be created using any     *)
(*                               text editor that produces ascii files. *)
(*                               The format is simply:                  *)
(*                                                                      *)
(*                                  firstname;lastname;password;priv    *)
(*                                                                      *)
(*                               i.e., semicolons separating the first  *)
(*                               name, last name, password, and         *)
(*                               privilege level.  At present, the only *)
(*                               privilege levels are 'N' for normal    *)
(*                               users and 'S' for special users.       *)
(*                                                                      *)
(*                               This file MUST be created outside of   *)
(*                               PibTerm;  there are no provisions for  *)
(*                               a remote caller to get added to the    *)
(*                               user file.                             *)
(*                                                                      *)
(*              PIBTERM.MSG ---  The message file.  This file is also   *)
(*                               a simple ascii text file.  Message     *)
(*                               header information is flagged by '=='  *)
(*                               in columns one and two.  The end of a  *)
(*                               message is marked by '== End' in       *)
(*                               column one.  This file will be created *)
(*                               by PibTerm if it doesn't exist when a  *)
(*                               host session requires its presence.    *)
(*                                                                      *)
(*                               To remove messages, use a text editor  *)
(*                               and just delete the header lines and   *)
(*                               text for a message.  There are no      *)
(*                               provisions for deleting messages       *)
(*                               remotely.                              *)
(*                                                                      *)
(*              PIBTERM.XFR ---  The file transfer list.  This file     *)
(*                               contains a list of files which may be  *)
(*                               downloaded by a remote user.  Files    *)
(*                               NOT on the transfer list cannot be     *)
(*                               downloaded.                            *)
(*                                                                      *)
(*                               Also, a file with the same name as a   *)
(*                               file on this list cannot be uploaded   *)
(*                               by a remote user.                      *)
(*                                                                      *)
(*                               If the file name begins with an '*',   *)
(*                               then that file is protected, and it    *)
(*                               can neither be uploaded nor downloaded.*)
(*                               All the PibTerm files should be placed *)
(*                               in PIBTERM.XFR with an '*' preceding   *)
(*                               the name.  For example:                *)
(*                                                                      *)
(*                                   *PIBTERM.XFR                       *)
(*                                                                      *)
(*              PIBTERM.CMT ---  private comments file -- only readable *)
(*                               by you.  The format is the same as the *)
(*                               message file.                          *)
(*                                                                      *)
(*              PIBTERM.LOG ---  log file telling who logged on and     *)
(*                               when they logged off.                  *)
(*                                                                      *)
(*              PIBTERM.WEL ---  Welcome message file issued after a    *)
(*                               sucessful login.                       *)
(*                                                                      *)
(*            Note that all these files are simple sequential ascii     *)
(*            files. This implies that they should be kept small for    *)
(*            reasonable performance -- which is fine for a small group *)
(*            of users.  This implementation does not provide good      *)
(*            performance for a large group of users;  if you need that,*)
(*            you should obtain a real BBS program designed to handle   *)
(*            large numbers of users.                                   *)
(*                                                                      *)
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

(*----------------------------------------------------------------------*)
(*                    Global host mode variables                        *)
(*----------------------------------------------------------------------*)

CONST
   MaxUsers      = 100             (* Maximum number of users supported *);
   Page_Size     = 23              (* No. lines per screen for display  *);
   Max_Login_Try = 3               (* Max. number of tries for login    *);

TYPE                               (* Information about a user *)

   User_Record = RECORD
                    First_Name: STRING[20];
                    Last_Name : STRING[20];
                    Password  : STRING[10];
                    Privilege : STRING[1];
                 END;

   User_List_Type     = ARRAY[1 .. MaxUsers] OF User_Record;
   User_List_Ptr_Type = ^User_List_Type;

VAR

   Done              : BOOLEAN     (* If session complete        *);
   Really_Done       : BOOLEAN     (* To leave host mode         *);

   Kbd_Input         : BOOLEAN     (* Input found at host keybrd *);
   Fname             : ShortStr    (* First name of caller       *);
   Lname             : ShortStr    (* Last name of caller        *);
   PassWord          : ShortStr    (* Password to access system  *);
   First_Time        : BOOLEAN     (* If first time host mode up *);
   Recipient_Name    : FileStr     (* Name for message reception *);
   Message_Subject   : AnyStr      (* Subject of message         *);
   Message_Line      : AnyStr      (* Text line for message      *);

   CR_LF_Host        : STRING[2]   (* CR or CR+LF                *);
   Expert_On         : BOOLEAN     (* TRUE to use short menus    *);

   Message_File      : Text_File   (* Message file               *);

                                   (* User list *)

   User_List         : User_List_Ptr_Type;

   One_User          : User_Record (* User list for one-user mode*);

   NUsers            : INTEGER     (* Number of active users     *);

   User_File_Size    : INTEGER     (* # of lines in user file    *);

   Cur_User          : INTEGER     (* Current user               *);
   Cur_User_Name     : FileStr     (* Current user's name        *);

   NMessages         : INTEGER     (* Number of messages         *);

   Local_Host        : BOOLEAN     (* TRUE if local host session *);
   Host_Section      : CHAR        (* Which section are we in?   *);
   Last_Host_Sect    : CHAR        (* Section we were in before  *);
                                   (* gossip mode started        *)
   Blank_Time        : LONGINT     (* Time between sessions      *);

   Save_Upload       : FileStr     (* Save emul. mode upload path   *);
   Save_Download     : FileStr     (* Save emul. mode download path *);
   Save_Review       : BOOLEAN     (* Save review mode              *);
   Save_Logging      : BOOLEAN     (* Save logging status           *);
   Ierr              : INTEGER     (* I/O error flag                *);
   New_Baud          : WORD        (* New baud rate                 *);
   Save_H_Parity     : CHAR        (* Saves parity                  *);
   Save_H_Data_Bits  : INTEGER     (* Saves data bits               *);
   Save_H_Stop_Bits  : INTEGER     (* Saves stop bits               *);
   Save_H_Baud_Rate  : WORD        (* Saves baud rate               *);
   Cur_Host_Status   : ShortStr    (* Current host status for disp. *);
   Host_IO_Error     : INTEGER     (* General I/O error check var   *);

(*----------------------------------------------------------------------*)
(*        Host_Carrier_Detect --- Check for carrier or local mode       *)
(*----------------------------------------------------------------------*)

FUNCTION Host_Carrier_Detect : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:  Host_Carrier_Detect                                   *)
(*                                                                      *)
(*     Purpose:   Reports on carrier detect/local host mode status      *)
(*                                                                      *)
(*     Calling sequence:                                                *)
(*                                                                      *)
(*        Carrier := Host_Carrier_Detect : BOOLEAN;                     *)
(*                                                                      *)
(*           Carrier --- set TRUE if local host session, or if          *)
(*                       carrier detected for remote session.           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Host_Carrier_Detect *)

   Host_Carrier_Detect := FALSE;

   IF Local_Host THEN
      Host_Carrier_Detect := TRUE
   ELSE
      Host_Carrier_Detect := Async_Carrier_Detect;

END   (* Host_Carrier_Detect *);

(*----------------------------------------------------------------------*)
(*        Host_Send  ---  Send character to port/screen in host mode    *)
(*----------------------------------------------------------------------*)

PROCEDURE Host_Send( Ch : CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Host_Send                                            *)
(*                                                                      *)
(*     Purpose:    Sends character to comm port and/or screen           *)
(*                                                                      *)
(*     Calling sequence:                                                *)
(*                                                                      *)
(*        Host_Send( Ch : CHAR );                                       *)
(*                                                                      *)
(*           Ch --- character to be sent out                            *)
(*                                                                      *)
(*     Remarks:  If local host session, character is NOT sent out port. *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Host_Send *)

   IF ( NOT Local_Host ) THEN
      Async_Send( Ch );

   WRITE( Ch );

END   (* Host_Send *);

(*----------------------------------------------------------------------*)
(*   Host_Send_String  ---  Send string to port/screen in host mode     *)
(*----------------------------------------------------------------------*)

PROCEDURE Host_Send_String( S : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Host_Send_String                                     *)
(*                                                                      *)
(*     Purpose:    Sends string to comm port and/or screen              *)
(*                                                                      *)
(*     Calling sequence:                                                *)
(*                                                                      *)
(*        Host_Send_String( S : AnyStr );                               *)
(*                                                                      *)
(*           S --- character to be sent out                             *)
(*                                                                      *)
(*     Remarks:  If local host session, string is NOT sent out port.    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Host_Send_String *)

   IF ( NOT Local_Host ) THEN
      Async_Send_String( S );

   WRITE( S );

   IF Printer_On THEN
      Write_Prt_Str( S );

   IF Capture_On THEN
      WRITE( Capture_File , S );

END   (* Host_Send_String *);

(*----------------------------------------------------------------------*)
(*   Host_Send_String_With_CR --- Append CR or CR+LF and send string    *)
(*----------------------------------------------------------------------*)

PROCEDURE Host_Send_String_With_CR( S : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Host_Send_String_With_CR                              *)
(*                                                                      *)
(*     Purpose:   Appends end-of-line characters to string and sends    *)
(*                it out over communications port.                      *)
(*                                                                      *)
(*     Calling sequence:                                                *)
(*                                                                      *)
(*        Host_Send_String_With_CR( S: AnyStr );                        *)
(*                                                                      *)
(*           S --- string to be sent out.                               *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The end-of-line characters are either a CR or a CR+LF,        *)
(*        depending upon the choice made by the user at login time.     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Host_Send_String_With_CR *)

   IF ( NOT Local_Host ) THEN
      Async_Send_String( S + CR_LF_Host );

   WRITELN( S );

   IF Printer_On THEN
      BEGIN
         Write_Prt_Str( S );
         Write_Prt_Str( CRLF_String );
      END;

   IF Capture_On THEN
      WRITELN( Capture_File , S );

END   (* Host_Send_String_With_CR *);

(*----------------------------------------------------------------------*)
(*    Host_Send_String_And_Echo --- Send string and echo it to screen   *)
(*----------------------------------------------------------------------*)

PROCEDURE Host_Send_String_And_Echo( S : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Host_Send_String_And_Echo                             *)
(*                                                                      *)
(*     Purpose:   Send string out com port and echo to screen           *)
(*                                                                      *)
(*     Calling sequence:                                                *)
(*                                                                      *)
(*        Host_Send_String_And_Echo( S: AnyStr );                       *)
(*                                                                      *)
(*           S --- string to be sent out and echoed.                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Host_Send_String_And_Echo *)

   IF ( NOT Local_Host ) THEN
      Async_Send_String( S );

   WRITE( S );

   IF Printer_On THEN
      Write_Prt_Str( S );

   IF Capture_On THEN
      WRITE( Capture_File , S );

END   (* Host_Send_String_And_Echo *);

(*----------------------------------------------------------------------*)
(*    Host_Prompt_And_Read_String --- Get string from remote and echo   *)
(*----------------------------------------------------------------------*)

PROCEDURE Host_Prompt_And_Read_String(      Prompt : AnyStr;
                                        VAR S      : AnyStr;
                                            Echo   : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Host_Prompt_And_Read_String                           *)
(*                                                                      *)
(*     Purpose:   Issues prompt to remote user, reads response, and     *)
(*                echos response.                                       *)
(*                                                                      *)
(*     Calling sequence:                                                *)
(*                                                                      *)
(*        Host_Prompt_And_Read_String(      Prompt : AnyStr;            *)
(*                                      VAR S      : AnyStr;            *)
(*                                          Echo   : BOOLEAN );         *)
(*                                                                      *)
(*           Prompt --- prompt string to be issued.                     *)
(*                      If null, no prompt is issued.                   *)
(*           S      --- resulting string received from remote user.     *)
(*           Echo   --- TRUE to echo characters as they are read;       *)
(*                      FALSE to echo characters as '.'s.  This is      *)
(*                      useful for getting passwords.                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Ch      : CHAR;
   GotChar : BOOLEAN;
   XPos    : INTEGER;
   Rem_Ch  : CHAR;

BEGIN (* Host_Prompt_And_Read_String *)

                                   (* Send prompt to remote user *)
   IF LENGTH( Prompt ) > 0 THEN
      Host_Send_String_And_Echo( Prompt );

   Ch      := CHR( 0 );
   S       := '';
   XPos    := WhereX;
                                   (* Get response string        *)
   REPEAT

      GotChar := FALSE;

      IF PibTerm_KeyPressed THEN
         BEGIN
            Read_Kbd( Ch );
            GotChar := TRUE;
         END;

      IF Async_Receive( Rem_Ch ) THEN
         BEGIN
            Ch      := Rem_Ch;
            GotChar := TRUE;
         END;

      IF ( NOT GotChar ) THEN
         GiveAwayTime( 2 )
      ELSE
         IF Ch <> CHR( CR ) THEN
            IF Ch = ^H THEN
               BEGIN  (* Backspace *)
                  IF WhereX > Xpos THEN
                     BEGIN
                        Host_Send( Ch  );
                        Host_Send( ' ' );
                        Host_Send( Ch  );
                        S := COPY( S, 1, PRED( LENGTH( S ) ) );
                     END;
               END   (* Backspace *)
            ELSE
               IF ( Ch <> ^X ) THEN
                  BEGIN
                     S := S + Ch;
                     IF Echo THEN
                        Host_Send( Ch )
                     ELSE
                        Host_Send( '.' );
                  END;

   UNTIL ( Ch = CHR( CR ) ) OR
         ( Ch = ^X        ) OR
         ( NOT Host_Carrier_Detect );

                                   (* CR ends line *)
   IF ( Ch = ^X ) THEN
      BEGIN
         S := ^X;
         Host_Send_String_And_Echo(' *** Cancelled');
         WRITELN;
      END
   ELSE IF Host_Carrier_Detect THEN
      BEGIN

         WRITELN;

         IF Printer_On THEN
            BEGIN
               Write_Prt_Str( Write_Ctrls( S ) );
               Write_Prt_Str( CRLF_String );
            END;

         IF Capture_On THEN
            WRITELN( Capture_File , S );

      END;

END   (* Host_Prompt_And_Read_String *);

(*----------------------------------------------------------------------*)
(*           Host_Status --- update status line in host mode            *)
(*----------------------------------------------------------------------*)

PROCEDURE Host_Status( Message : ShortStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Host_Status                                          *)
(*                                                                      *)
(*     Purpose:    Update status line in host mode                      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Host_Status( Message : ShortStr );                            *)
(*                                                                      *)
(*           Message    --- Text to display on status line              *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Host_Status *)

   IF ( LENGTH( Message ) < 15 ) THEN
      Write_To_Status_Line( Message + DUPL( ' ' , 15 - LENGTH( Message ) ) , 65 )
   ELSE
      Write_To_Status_Line( COPY( Message, 1, 15 ) , 65 );

END   (* Host_Status *);

(*----------------------------------------------------------------------*)
(*           List_Prompt --- prompt for end-of-screen                   *)
(*----------------------------------------------------------------------*)

PROCEDURE List_Prompt( VAR List_Count : INTEGER; VAR List_Done : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  List_Prompt                                          *)
(*                                                                      *)
(*     Purpose:    Issues end-of-screen prompt for view routines        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        List_Prompt( VAR List_Count : INTEGER;                        *)
(*                     VAR List_Done  : BOOLEAN );                      *)
(*                                                                      *)
(*           List_Done  --- TRUE if Stop option selected here           *)
(*           List_Count --- Count of lines per panel.  May be changed   *)
(*                          here if C option selected.                  *)
(*                                                                      *)
(*     Calls:   RvsVideoOn                                              *)
(*              RvsVideoOff                                             *)
(*                                                                      *)
(*     Called by:                                                       *)
(*                                                                      *)
(*        List_Files_For_Transfer                                       *)
(*        Read_Messages                                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   List_Char : CHAR;
   Found_Char: BOOLEAN;

CONST
   List_Prompt_String : STRING[59] =
                        'Enter <CR> to continue, S to stop, C to continue non-stop: ';

BEGIN (* List_Prompt *)

   INC( List_Count );

   IF List_Count > Page_Size THEN
      BEGIN (* Do end of screen prompt *)

         REPEAT

            Host_Send_String_And_Echo( List_Prompt_String );

            REPEAT
               Found_Char := Async_Receive( List_Char ) OR PibTerm_KeyPressed;
               IF ( NOT Found_Char ) THEN
                  GiveAwayTime( 2 );
               Update_Status_Line;
            UNTIL ( Found_Char OR ( NOT Host_Carrier_Detect ) );

            IF PibTerm_KeyPressed THEN
               Read_Kbd( List_Char );

            IF List_Char = CHR( CR ) THEN
               List_Char := ' ';
{
            Host_Send_String( List_Char );
            Host_Send_String( CHR( CR ) );
}
            Host_Send_String_With_CR( List_Char );

            IF Printer_On THEN
               Write_Prt_Str( List_Char + CRLF_String );

            IF Capture_On THEN
               WRITELN( Capture_File , List_Char );

            List_Char := UpCase( List_Char );

         UNTIL ( List_Char IN ['S', 'C', ' '] ) OR ( NOT Host_Carrier_Detect );

         CASE List_Char Of
            'C':  List_Count := -MaxInt;
            'S':  List_Done  := TRUE;
            ' ':  List_Count := 1;
            ELSE
                  ;
         END (* CASE *);

      END (* Do end of screen prompt *);

END  (* List_Prompt *);

(*----------------------------------------------------------------------*)
(*            End_Prompt --- prompt for end of message batch            *)
(*----------------------------------------------------------------------*)

PROCEDURE End_Prompt( Mess: AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  End_Prompt                                           *)
(*                                                                      *)
(*     Purpose:    Issues prompt at end of message batch                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        End_Prompt( Mess : AnyStr );                                  *)
(*                                                                      *)
(*           Mess --- Message to issue                                  *)
(*                                                                      *)
(*     Calls:   RvsVideoOn                                              *)
(*              RvsVideoOff                                             *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   List_Char : CHAR;
   Found_Char: BOOLEAN;

BEGIN (* List_Prompt *)

   Host_Send_String_With_CR(' ');
   Host_Send_String_And_Echo( Mess );

   REPEAT
      Found_Char := Async_Receive( List_Char ) OR PibTerm_KeyPressed;
      IF ( NOT Found_Char ) THEN
         GiveAwayTime( 2 );
   UNTIL ( Found_Char OR ( NOT Host_Carrier_Detect ) );

   IF PibTerm_KeyPressed THEN
      Read_Kbd( List_Char );

   IF List_Char = CHR( CR ) THEN
      List_Char := ' ';

   Host_Send_String_With_CR( List_Char );

   IF Printer_On THEN
      Write_Prt_Str( List_Char + CRLF_String );
   IF Capture_On THEN
      WRITELN( Capture_File , List_Char );

END  (* List_Prompt *);

(*----------------------------------------------------------------------*)
(*                   Gossip_Mode --- Enter PibTerm gossip mode          *)
(*----------------------------------------------------------------------*)

PROCEDURE Gossip_Mode;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Gossip_Mode                                          *)
(*                                                                      *)
(*     Purpose:    Allows "conversation" with remote user.              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Gossip_Mode;                                                  *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*         This gossip mode feature does not use a split screen.        *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Gossip_Done : BOOLEAN           (* TRUE to exit back to host mode       *);
   Ch          : CHAR              (* Character read/written               *);
   Bozo        : BOOLEAN;

BEGIN (* Gossip_Mode *)

   Write_Log( 'Entered gossip mode.', FALSE, FALSE );

   Host_Status('Gossip mode');

   Host_Send_String_With_CR(' ');
   Host_Send_String_With_CR('Entering gossip mode, hit ^X to exit ... ');
   WRITELN('Hit ^X to exit gossip mode.');

   Gossip_Done := FALSE;
                                   (* Loop over input until done *)
   WHILE ( NOT Gossip_Done ) DO
      BEGIN
                                   (* Check for character typed at keyboard *)
         IF PibTerm_KeyPressed THEN
            BEGIN

               Read_Kbd( Ch );

               IF ( ORD( Ch ) = ESC ) AND PibTerm_KeyPressed THEN
                  BEGIN
                     Read_Kbd( Ch );
                     CASE ORD( Ch ) OF
                        F1 : Ch := CHR( 3 );
                        F2 : BEGIN
                                Ch   := CHR( 3 );
                                Done := TRUE;
                             END;
                        F3 : BEGIN
                                DosJump('');
                                Ch := CHR( 0 );
                             END;
                        F5 : BEGIN
                                WRITELN;
                                WRITELN('Current caller is ',Cur_User_Name);
                                Ch := CHR( 0 );
                             END;
                     END (* CASE *);
                  END;

               CASE ORD( Ch ) OF

                   0:   ;

                   3,
                   24:  Gossip_Done := TRUE;

                   BS:  BEGIN
                           Host_Send_String( BS_String );
                           IF Printer_On THEN
                              Write_Prt( Ch );
                           IF Capture_On THEN
                              WRITE( Capture_File , Ch );
                        END;

                  DEL:  BEGIN
                           Host_Send_String( Ctrl_BS_String );
                           IF Printer_On THEN
                              Write_Prt( Ch );
                           IF Capture_On THEN
                              WRITE( Capture_File , Ch );
                        END;

                  CR:   BEGIN
                           Host_Send_String( CR_LF_Host );
                           IF Printer_On THEN
                              Write_Prt_Str( CRLF_String );
                           IF Capture_On THEN
                              WRITELN( Capture_File );
                        END;

                  ELSE
                        BEGIN
                           Host_Send( Ch );
                           IF Printer_On THEN
                              Write_Prt( Ch );
                           IF Capture_On THEN
                              WRITE( Capture_File , Ch );
                        END;

               END (* CASE ORD( Ch ) *);

            END;

         IF Async_Receive( Ch ) THEN
            BEGIN
               IF ( Ch = ^X ) THEN
                  Gossip_Done := TRUE
               ELSE IF Ch = CHR( CR ) THEN
                  BEGIN
                     IF Printer_On THEN
                        Write_Prt_Str( CRLF_String );
                     IF Capture_On THEN
                        WRITELN( Capture_File );
                     Host_Send_String( CR_LF_Host );
                  END
               ELSE
                  Host_Send( Ch );
            END
         ELSE
            IF ( NOT PibTerm_KeyPressed ) THEN
               GiveAwayTime( 2 );

      END;

   Host_Section := Last_Host_Sect;

   Host_Status( Cur_Host_Status );
   Write_Log( 'Exited gossip mode.', FALSE, FALSE );

END   (* Gossip_Mode *);

