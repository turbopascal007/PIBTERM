(*----------------------------------------------------------------------*)
(*                PibDialer --- Dialing Management                      *)
(*----------------------------------------------------------------------*)

PROCEDURE PibDialer( ReDial         : BOOLEAN;
                     Dialing_String : AnyStr;
                     Allow_Script   : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  PibDialer                                            *)
(*                                                                      *)
(*     Purpose:    Main routine for dials/redials                       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        PibDialer( ReDial         : BOOLEAN;                          *)
(*                   Dialing_String : AnyStr );                         *)
(*                                                                      *)
(*           ReDial --- TRUE for redial, FALSE for ordinary dial        *)
(*           Dialing_String --- if not null, use this as number to      *)
(*                              be dialed.                              *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*           Dial_A_Number                                              *)
(*           Redial_A_Number                                            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   Empty_Name   = '-------------------------';
   Empty_Number = ' # ### ###-####';

VAR
   Local_Save_4       : Saved_Screen_Ptr;
   Session_Active     : BOOLEAN;
   Xpos1              : INTEGER;
   Manual_Dial        : BOOLEAN;
   Quit               : BOOLEAN;
   Use_Short_Prompt   : BOOLEAN;
   Entry_String       : STRING[30];
   First_Display_Time : BOOLEAN;
   Dial_Search_String : AnyStr;
   Saved_Insert_Mode  : BOOLEAN;
   Connection_Made    : BOOLEAN;
   Redial_Count       : INTEGER;
   SVal               : STRING[10];
   Ch                 : CHAR;

(*----------------------------------------------------------------------*)
(*          Dialer_Carrier_Detect --- Look for carrier detect           *)
(*----------------------------------------------------------------------*)

FUNCTION Dialer_Carrier_Detect : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:  Dialer_Carrier_Detect                                 *)
(*                                                                      *)
(*     Purpose:   Looks for a carrier detect                            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Carrier := Dialer_Carrier_Detect;                             *)
(*                                                                      *)
(*           Carrier  --- TRUE if carrier detect found                  *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Async_Carrier_Detect;                                         *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine is essentially a filter for Async_Carrier_Detect *)
(*        except that if the global flag Modem_Carrier_High is set, it  *)
(*        returns FALSE.  This is to support modems which always keep   *)
(*        the carrier detect line high.                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Dialer_Carrier_Detect *)

   IF Modem_Carrier_High THEN
      Dialer_Carrier_Detect := FALSE
   ELSE
      Dialer_Carrier_Detect := Async_Carrier_Detect;

END   (* Dialer_Carrier_Detect *);

(*----------------------------------------------------------------------*)
(*          Read_Number_Or_ESC --- Read in number or get escape         *)
(*----------------------------------------------------------------------*)

PROCEDURE Read_Number_Or_ESC(     Ch        : CHAR;
                                  Xpos      : INTEGER;
                                  Xlen      : INTEGER;
                              VAR SNumber   : AnyStr;
                              VAR Pre_Str   : AnyStr;
                              VAR Post_Str  : AnyStr;
                              VAR Esc_Found : BOOLEAN;
                              VAR Number    : INTEGER;
                              VAR Entry_Str : AnyStr   );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Read_Number_Or_ESC                                   *)
(*                                                                      *)
(*     Purpose:    Reads in number and reports if escape hit.           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Read_Number_Or_ESC(     Ch        : CHAR;                     *)
(*                                Xpos      : INTEGER;                  *)
(*                                Xlen      : INTEGER;                  *)
(*                            VAR SNumber   : AnyStr;                   *)
(*                            VAR Pre_Str   : AnyStr;                   *)
(*                            VAR Post_Str  : AnyStr;                   *)
(*                            VAR Esc_Found : BOOLEAN;                  *)
(*                            VAR Number    : INTEGER;                  *)
(*                            VAR Entry_Str : AnyStr  );                *)
(*                                                                      *)
(*           Ch        --- First character in number (input)            *)
(*           XPos      --- First column of answer                       *)
(*           Xlen      --- Maximum columns in answer                    *)
(*           SNumber   --- Full number if found                         *)
(*           Pre_Str   --- Prefix string if any found                   *)
(*           Post_Str  --- Postfix string if any found                  *)
(*           Esc_Found --- Escape encountered                           *)
(*           Number    --- Resultant number                             *)
(*           Entry_Str --- Full text of string typed in                 *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Menu_Beep                                                     *)
(*        Read_Kbd                                                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   IX      : INTEGER;
   IY      : INTEGER;
   Ierr    : INTEGER;
   A_Ch    : CHAR;

BEGIN (* Read_Number_Or_ESC *)

                                   (* Initialize arguments         *)
   ESC_Found := FALSE;
   SNumber   := Ch;
   Pre_Str   := '';
   Post_Str  := '';
   Number    := 0;
   Entry_Str := '';
                                   (* Pick up the number, possibly  *)
                                   (* with dialing prefix or ESC    *)

   TextColor( Menu_Text_Color );

   A_Ch := Edit_String( SNumber, Xlen, WhereX, WhereX + 1, WhereY,
                        Xlen, FALSE, 0 );

                                   (* No number entered -- quit *)

   ESC_Found := ( A_Ch = CHR( ESC ) );

   IF ( LENGTH( SNumber ) <= 0 ) OR ( ESC_Found ) THEN EXIT;

                                   (* Save number as entered *)
   Entry_Str := SNumber;
                                   (* Remove prefix if any *)

   IF SNumber[1] IN ['+','-','!','@','#'] THEN
      BEGIN
         Pre_Str    := Phone_Prefix_Nos[ POS( SNumber[1], '+-!@#' ) ];
         SNumber    := COPY( SNumber, 2, LENGTH( SNumber ) - 1 );
      END;
                                   (* Remove postfix if any *)

   IF SNumber[LENGTH(SNumber)] IN ['+','-','!','@','#'] THEN
      BEGIN
         Post_Str   := Phone_Prefix_Nos[ POS( SNumber[LENGTH(SNumber)],
                                              '+-!@#' ) ];
         SNumber    := COPY( SNumber, 1, LENGTH( SNumber ) - 1 );
      END;

                                   (* Convert number *)
   Number := 0;
   Ierr   := 0;

   FOR IX := 1 TO LENGTH( SNumber ) DO
      IF SNumber[IX] IN ['0'..'9'] THEN
         Number := Number * 10 + ORD( SNumber[IX] ) - ORD('0')
      ELSE IF ( NOT ( UpCase( SNumber[IX] ) IN ['M','G','*','#',',',' '] ) ) THEN
         Ierr := 1;
                                   (* If bad, beep and ignore. *)
   IF ( Ierr > 0 ) THEN
      BEGIN
         Menu_Beep;
         Number := 0;
         EXIT;
      END;

END   (* Read_Number_Or_ESC *);

(*----------------------------------------------------------------------*)
(*       Update_Phone_File --- Update dialing directory file entry      *)
(*----------------------------------------------------------------------*)

PROCEDURE Update_Phone_File( Phone_Entry_Data: Phone_Number_Record;
                             Phone_Record    : INTEGER ) ;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Update_Phone_File                                    *)
(*                                                                      *)
(*     Purpose:    Updates entry in dialing directory file.             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Update_Phone_File( Phone_Entry_Data: Phone_Number_Record;     *)
(*                           Phone_Record    : INTEGER );               *)
(*                                                                      *)
(*           Phone_Entry_Data --- data record for revised dialing entry *)
(*           Phone_Record     --- record to be updated                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Update_Phone_File *)
                                   (* Update in-core list as well *)

   Dialing_Directory^[Phone_Record] := Phone_Entry_Data;
   Any_Dialing_Changes              := TRUE;

END   (* Update_Phone_File *);

(*----------------------------------------------------------------------*)
(*    Reset_Comm_Params --- Reset comm. parms. from dialing entry       *)
(*----------------------------------------------------------------------*)

PROCEDURE Reset_Comm_Params( Phone_Entry_Data: Phone_Number_Record;
                             Entry_Number    : INTEGER              ) ;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Reset_Comm_Params                                    *)
(*                                                                      *)
(*     Purpose:    Resets communications parameters (baud,parity,etc.)  *)
(*                 according to selected dialing directory entry.       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Reset_Comm_Params( Phone_Entry_Data: Phone_Number_Record;     *)
(*                           Entry_Number    : INTEGER             );   *)
(*                                                                      *)
(*           Phone_Entry_Data --- data record for a dialing entry       *)
(*           Entry_Number     --- number of this entry in dialing dir.  *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Async_Reset_Port                                              *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Qerr: BOOLEAN;
   S:    ShortStr;
   I:    INTEGER;
   J:    INTEGER;
   T:    Terminal_Type;

BEGIN (* Reset_Comm_Params *)
                                   (* Get parameters needed for dialing *)
   WITH Phone_Entry_Data DO
      BEGIN

         S := Phone_Baud;

         I := 0;

         FOR J := 1 TO LENGTH( S ) DO
            IF S[J] IN ['0'..'9'] THEN
               I := I * 10 + ORD( S[J] ) - ORD('0');

         Baud_Rate := I;

         Parity := Phone_Parity;

         Data_Bits := ORD( Phone_DataBits ) - ORD('0');

         Stop_Bits := ORD( Phone_StopBits ) - ORD('0');

         Reset_Comm_Port := TRUE;

         Async_Reset_Port( Comm_Port, Baud_Rate,
                           Parity, Data_Bits, Stop_Bits );

         IF Do_Status_Line THEN
            BEGIN
               Set_Status_Line_Name( Short_Terminal_Name );
               Write_To_Status_Line( Status_Line_Name, 1 );
            END;

      END;

END   (* Reset_Comm_Params *);

(*----------------------------------------------------------------------*)
(*    Reset_Other_Params --- Reset other parms. from dialing entry      *)
(*----------------------------------------------------------------------*)

PROCEDURE Reset_Other_Params( Phone_Entry_Data: Phone_Number_Record;
                              Entry_Number    : INTEGER              ) ;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Reset_Other_Params                                   *)
(*                                                                      *)
(*     Purpose:    Resets other params (transfer type, date/time, etc.) *)
(*                 according to selected dialing directory entry.       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Reset_Other_Params( Phone_Entry_Data: Phone_Number_Record;    *)
(*                            Entry_Number    : INTEGER             );  *)
(*                                                                      *)
(*           Phone_Entry_Data --- data record for a dialing entry       *)
(*           Entry_Number     --- number of this entry in dialing dir.  *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        CopySTOA                                                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Qerr: BOOLEAN;
   S:    ShortStr;
   I:    INTEGER;
   J:    INTEGER;
   T:    Terminal_Type;

BEGIN (* Reset_Other_Params *)

   WITH Phone_Entry_Data DO
      BEGIN

         IF ( Phone_Echo <> ' ' ) THEN
            Local_Echo := ( Phone_Echo = 'Y' );

         CASE Phone_BackSpace OF
            'B': BEGIN
                    BS_String      := CHR( BS );
                    Ctrl_BS_String := CHR( DEL );
                 END;
            'D': BEGIN
                    BS_String      := CHR( DEL );
                    Ctrl_BS_String := CHR( BS  );
                 END;
            ELSE;
         END;

         IF ( Phone_LineFeed <> ' ' ) THEN
            Add_LF := ( Phone_LineFeed = 'Y' );

         IF ( Phone_Term_Type IN ['0'..'9', 'A'..'F'] ) THEN
            Terminal_To_Emulate :=
               Terminal_Type_List[ Hex_To_Dec( Phone_Term_Type , 0 ) ];

         IF ( Phone_Trans_Type <> '  ' ) THEN
            BEGIN
               FOR I := 1 TO Max_Transfer_Types DO
                  IF ( Phone_Trans_Type = Trans_Type_Name[Transfers[I]] ) THEN
                     Default_Transfer_Type := Transfers[I];
            END;

         CopySToA( DialDateString, Phone_Last_Date, 8 );

         S := TimeString( TimeOfDay , Military_Time );

         IF ( S[1] = ' ' ) THEN
            S[1] := '0';

         CopySToA( S, Phone_Last_Time, 8 );

         Dialing_Directory^[Entry_Number] := Phone_Entry_Data;
         Any_Dialing_Changes              := TRUE;

      END;
                                   (* Make sure script gets processed *)

   IF ( Phone_Entry_Data.Phone_Script <> '         ' ) AND
      ( NOT Script_Learn_Mode                        ) AND
      ( Allow_Script                                 ) THEN
      BEGIN
         Script_File_Name := Phone_Entry_Data.Phone_Script;
         Read_In_Script   := TRUE;
      END;

END   (* Reset_Other_Params *);

(*----------------------------------------------------------------------*)
(*         Display_Phone_Numbers --- display dialing directory          *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Phone_Numbers( VAR Entry_String: AnyStr;
                                 VAR Phone_Number: AnyStr;
                                 VAR Prefix_Str  : AnyStr;
                                 VAR Postfix_Str : AnyStr;
                                 VAR Esc_Hit     : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Display_Phone_Numbers                                *)
(*                                                                      *)
(*     Purpose:    Displays dialing directory and prompts for # to dial *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Display_Phone_Numbers( VAR Entry_String: AnyStr               *)
(*                               VAR Phone_Number: AnyStr;              *)
(*                               VAR Prefix_Str  : AnyStr;              *)
(*                               VAR Postfix_Str : AnyStr;              *)
(*                               VAR Esc_Hit     : BOOLEAN );           *)
(*                                                                      *)
(*           Entry_String --- dialing # in character form               *)
(*           Phone_Number --- phone number to dial (if any)             *)
(*           Prefix_Str   --- prefix string to use                      *)
(*           Postfix_Str  --- postfix string to use                     *)
(*           Esc_Hit      --- TRUE if ESC hit to exit dialing           *)
(*                                                                      *)
(*     Calls:   Display_Directory_Page                                  *)
(*              Dialer_Carrier_Detect                                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   N_nos = 15                      (* No. of phone numbers displayed *);

VAR
   Fixed_Entry  : Phone_Number_Record;
   Low_Num      : INTEGER;
   Hi_Num       : INTEGER;
   Done         : BOOLEAN;
   I            : INTEGER;
   J            : INTEGER;
   L            : INTEGER;
   Dial_Func    : CHAR;
   SNumber      : STRING[40];
   Local_Save   : Saved_Screen_Ptr;
   Local_Save_2 : Saved_Screen_Ptr;
   Local_Save_3 : Saved_Screen_Ptr;
   Qerr         : BOOLEAN;
   XPos         : INTEGER;
   YPos         : INTEGER;
   ReDraw       : BOOLEAN;
   Save_Pre     : ShortStr;
   Save_Post    : ShortStr;
   SS           : AnyStr;
   Ch           : CHAR;
   Q            : BOOLEAN;

(*----------------------------------------------------------------------*)
(*     Display_One_Entry --- display one entry in phone directory       *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_One_Entry( Entry_No : INTEGER;
                             Line_No  : INTEGER;
                             Reverse  : BOOLEAN  );

VAR
   Dial_Entry_Line : AnyStr;
   BS_Str          : STRING[3];
   Term_Str        : STRING[7];
   Trans_Str       : STRING[12];
   Date_Str        : STRING[8];
   Time_Str        : STRING[8];
   I               : INTEGER;
   Ampm_Str        : STRING[2];

BEGIN (* Display_One_Entry *)

   WITH Dialing_Directory^[ Entry_No ] DO
      BEGIN

         STR( Entry_No:3 , Dial_Entry_Line );

         Dial_Entry_Line := Dial_Entry_Line + '  ' + Phone_Name + '  ';

         CASE Phone_BackSpace OF
            'B':  BS_Str := 'BS ';
            'D':  BS_Str := 'DEL';
            ELSE  BS_Str := '   ';
         END (* CASE *);

         CASE Phone_Term_Type OF
            '0'..'9':  BEGIN
                          I        := ( ORD(Phone_Term_Type) - ORD('0') );
                          Term_Str := Terminal_Name_List[ I ];
                       END;
            'A'..'F':  BEGIN
                          I        := ( ORD(Phone_Term_Type) - ORD('A') );
                          Term_Str := Terminal_Name_List[ I + 10 ];
                       END;
            ELSE       Term_Str := '   None';
         END  (* CASE *);

         I := LENGTH( Term_Str );

         IF ( I < 7 ) THEN
            Term_Str := DUPL( ' ' , 7 - I ) + Term_Str;

         IF ( Phone_Trans_Type = '  ' ) THEN
            Trans_Str := '        None'
         ELSE
            BEGIN
               FOR I := 1 TO Max_Transfer_Types DO
                  IF ( Phone_Trans_Type = Trans_Type_Name[Transfers[I]] ) THEN
                     Trans_Str := Transfer_Name_List[ I ];
            END;

         IF Phone_Last_Date = '        ' THEN
            Date_Str := '        '
         ELSE
            CASE Date_Format OF
               YMD_Style: Date_Str := Phone_Last_Date;
               DMY_Style: Date_Str := COPY( Phone_Last_Date, 7, 2 ) + '/' +
                                      COPY( Phone_Last_Date, 4, 2 ) + '/' +
                                      COPY( Phone_Last_Date, 1, 2 );
               ELSE       Date_Str := COPY( Phone_Last_Date, 4, 5 ) + '/' +
                                      COPY( Phone_Last_Date, 1, 2 );
            END (* CASE *);

         IF Phone_Last_Time = '        ' THEN
            Time_Str := '        '
         ELSE
            CASE Time_Format OF
               Military_Time: Time_Str := Phone_Last_Time;
               AMPM_Time    : BEGIN
                                 I := ( ORD( Phone_Last_Time[1] ) - ORD('0') )
                                      * 10 + ( ORD( Phone_Last_Time[2] ) - ORD('0') );
                                 Adjust_Hour( I , Ampm_Str );
                                 STR( I:2 , Time_Str );
                                 Time_Str := Time_Str + ':' +
                                             Phone_Last_Time[4] +
                                             Phone_Last_Time[5] +
                                             ' ' + Ampm_Str;
                              END;
               ELSE;
            END (* CASE *);

         CASE Dialing_Page OF

            1:  Dial_Entry_Line := Dial_Entry_Line +
                                   Phone_Number + '   ' + Phone_Baud + '    ' +
                                   Phone_DataBits + '      ' + Phone_Parity +
                                   '     ' + Phone_StopBits;

            2:  Dial_Entry_Line := Dial_Entry_Line +
                                   '  ' + Phone_Echo +
                                   '     ' + BS_Str + '     ' +
                                   Phone_LineFeed  + '      ' +
                                   Term_Str        + ' ' +
                                   Trans_Str;

            3:  Dial_Entry_Line := Dial_Entry_Line +
                                   Phone_Script    + '   '   +
                                   Date_Str        + '     ' +
                                   Time_Str;

         END (* CASE *);

         Dial_Entry_Line := Dial_Entry_Line +
                            DUPL( ' ' , 75 - LENGTH( Dial_Entry_Line ) );

         IF ( NOT Reverse ) THEN
            IF Write_Screen_Memory THEN
               WriteSXY( Dial_Entry_Line, 2, Line_No + 2, Menu_Text_Color )
            ELSE
               BEGIN
                  GoToXY( 1 , Line_No );
                  WRITELN ( Dial_Entry_Line );
               END
         ELSE
            BEGIN
               GoToXY( 1 , 1 );
               RvsVideoOn( Menu_Text_Color , BLACK );
               WRITELN( Dial_Entry_Line );
               RvsVideoOff( Menu_Text_Color , BLACK );
            END;

      END (* WITH *);

END   (* Display_One_Entry *);

(*----------------------------------------------------------------------*)
(*   Display_Directory_Page --- display a page of phone directory       *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Directory_Page;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Display_Directory_Page                               *)
(*                                                                      *)
(*     Purpose:    Displays one page of dialing directory               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Display_Directory_Page;                                       *)
(*                                                                      *)
(*     Calls:   WriteSXY                                                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I: INTEGER;
   
BEGIN (* Display_Directory_Page *)

   TextColor     ( Menu_Text_Color );
   TextBackGround( BLACK );
                                   (* Display entries              *)
   L := 0;

   FOR I := Low_Num TO Hi_Num DO
      BEGIN
         L := L + 1;
         Display_One_Entry( I , L , ( I = Low_Num ) );
      END;
                                   (* Blank out any remaining lines *)
   FOR I := ( L + 1 ) TO N_Nos DO
      BEGIN
         GoToXY( 1 , I );
         ClrEol;
      END;

END   (* Display_Directory_Page *);

(*----------------------------------------------------------------------*)
(*          Revise_Phone_Entry --- Revise phone directory entry         *)
(*----------------------------------------------------------------------*)

PROCEDURE Revise_Phone_Entry;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Revise_Phone_Entry                                   *)
(*                                                                      *)
(*     Purpose:    Handles revision of dialing directory entry          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Revise_Phone_Entry;                                           *)
(*                                                                      *)
(*     Calls:   Save_Screen                                             *)
(*              Draw_Menu_Frame                                         *)
(*              Restore_Screen                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   J           : INTEGER;
   Done        : BOOLEAN;
   I           : INTEGER;
   Quit        : BOOLEAN;
   Ch          : CHAR;
   S_No        : STRING[6];
   Revise_Menu : Menu_Type;
   Revise_Item : INTEGER;
   SNumber     : STRING[30];
   Changed_Any : BOOLEAN;
   Entry_Str   : AnyStr;
   X           : INTEGER;
   Y           : INTEGER;

(*----------------------------------------------------------------------*)
(*               Revise_Name --- Revise name of remote system           *)
(*----------------------------------------------------------------------*)

PROCEDURE Revise_Name;

VAR
   New_Name     : AnyStr;
   Local_SaveIt : Saved_Screen_Ptr;

BEGIN (* Revise_Name *)

   Draw_Titled_Box( Local_SaveIt, 10, 10, 65, 14, 'Name' );

   PibTerm_Window( 11, 11, 64, 13 );

   TextColor( Menu_Text_Color_2 );

   GoToXY( 1 , 1 );

   New_name := Fixed_Entry.Phone_Name;

   WRITELN('Old Name: ', New_Name );
   WRITE ('New Name: ');

   Saved_Insert_Mode := Edit_Insert_Mode;

   IF ( New_Name = Empty_Name ) THEN
      Edit_Insert_Mode := FALSE;

   TextColor( Menu_Text_Color );

   Read_Edited_String( New_Name );

   Edit_Insert_Mode := Saved_Insert_Mode;

   IF ( ( LENGTH( New_Name ) > 0 ) AND ( New_Name <> CHR( ESC ) ) ) THEN
      CopyStoA( New_Name , Fixed_Entry.Phone_Name , 25 );

   Restore_Screen( Local_SaveIt );

END   (* Revise_Name *);

(*----------------------------------------------------------------------*)
(*           Revise_Number --- Revise number of remote system           *)
(*----------------------------------------------------------------------*)

PROCEDURE Revise_Number;

VAR
   New_Number   : AnyStr;
   Local_SaveIt : Saved_Screen_Ptr;

BEGIN (* Revise_Number *)

   Draw_Titled_Box( Local_SaveIt, 10, 10, 65, 14, 'Number' );

   TextColor( Menu_Text_Color_2 );

   PibTerm_Window( 11, 11, 64, 13 );

   GoToXY( 1 , 1 );

   New_Number := LTrim( Fixed_Entry.Phone_Number );

   WRITELN('Old Number: ', New_Number );
   WRITE ('New Number: ');

   Saved_Insert_Mode := Edit_Insert_Mode;

   IF ( New_Number = LTrim( Empty_Number ) ) THEN
      Edit_Insert_Mode  := FALSE;

   TextColor( Menu_Text_Color );

   Read_Edited_String( New_Number );

   Edit_Insert_Mode  := Saved_Insert_Mode;

   IF ( New_Number <> CHR( ESC ) ) THEN
      BEGIN

         New_Number := LTrim( Trim( New_Number ) );

         WHILE( POS( '#' , New_Number ) <> 0 ) DO
            DELETE( New_Number, POS( '#' , New_Number ) , 1 );

         WHILE( New_Number[LENGTH( New_Number )] = '-' ) DO
            DELETE( New_Number, LENGTH( New_Number ), 1 );

         IF ( LENGTH( New_Number ) > 0 ) THEN
            CopyS2AR( New_Number , Fixed_Entry.Phone_Number , 15 );

      END;

   Restore_Screen( Local_SaveIt );

END   (* Revise_Number *);

(*----------------------------------------------------------------------*)
(*               Revise_Baud_Rate --- Revise Baud Rate                  *)
(*----------------------------------------------------------------------*)

PROCEDURE Revise_Baud_Rate;

VAR
   Baud_Menu   : Menu_Type;
   I           : INTEGER;
   Default     : INTEGER;
   B_Rate      : INTEGER;
   Baud_String : AnyStr;
   Baud_SVal   : STRING[5];

BEGIN (* Revise_Baud_Rate *)
                                   (* Get current baud rate *)
   B_Rate  := 0;
   Default := 0;

   FOR I := 1 TO 5 DO
      IF Fixed_Entry.Phone_Baud[I] IN ['0'..'9'] THEN
         B_Rate := B_Rate * 10 + ORD( Fixed_Entry.Phone_Baud[I] ) - ORD('0');

   Baud_String := '';

   FOR I := 1 TO N_Baud_Rates DO
      BEGIN
         IF B_Rate = Baud_Rates[I] THEN
            Default := I;
         STR( Baud_Rates[I] , Baud_SVal );
         Baud_String := Baud_String + Baud_SVal + ';';
      END;

   IF ( Default = 0 ) THEN
      Default := 5;
                                   (* Display menu and get choice *)

   Make_And_Display_Menu( Baud_Menu, N_Baud_Rates, 10, 30, 0, 0, Default,
                         'Choose Baud Rate: ',
                         Baud_String,
                         TRUE, TRUE, I );

   IF ( I > 0 ) THEN
      BEGIN
         STR( Baud_Rates[I] : 5 , S_No );
         CopyS2AR( S_No , Fixed_Entry.Phone_Baud , 5 );
      END;

END   (* Revise_Baud_Rate *);

(*----------------------------------------------------------------------*)
(*            Revise_Parity --- Revise Parity for Communications        *)
(*----------------------------------------------------------------------*)

PROCEDURE Revise_Parity;

CONST
   Parities:   ARRAY[ 1 .. 5 ] OF Char
               = ( 'E', 'O', 'N', 'M', 'S' );

VAR
   Parity_Menu   : Menu_Type;
   Default       : INTEGER;
   I             : INTEGER;

BEGIN (* Revise_Parity *)
                                   (* Get Current Parity *)
   Default := 3;

   FOR I := 1 TO 5 DO
      IF Fixed_Entry.Phone_Parity = Parities[I] THEN
         Default := I;
                                   (* Display menu and get choice *)

   Make_And_Display_Menu( Parity_Menu, 5, 10, 30, 0, 0, Default,
                          'Choose parity: ',
                          'Even;Odd;None;Mark;Space;',
                          FALSE, TRUE, I );

   IF ( I > 0 ) THEN
      Fixed_Entry.Phone_Parity := Parities[ I ];

END   (* Revise_Parity *);

(*----------------------------------------------------------------------*)
(*          Revise_Stop_Bits --- Revise Stop Bits for Communications    *)
(*----------------------------------------------------------------------*)

PROCEDURE Revise_Stop_Bits;

VAR
   Stop_Menu   : Menu_Type;
   I           : INTEGER;
   Default     : INTEGER;

BEGIN (* Revise_Stop_Bits *)
                                   (* Display menu and get choice *)

   IF ( Fixed_Entry.Phone_StopBits IN ['1',' '] ) THEN
      Default := 1
   ELSE
      Default := 2;

   Make_And_Display_Menu( Stop_Menu, 2, 10, 30, 0, 0, Default,
                          'Number of Stop Bits: ',
                          '1;2;',
                          FALSE, TRUE, I );

   IF ( I > 0 ) THEN
      Fixed_Entry.Phone_StopBits := CHR( ORD('0') + I );

END   (* Revise_Stop_Bits *);

(*----------------------------------------------------------------------*)
(*          Revise_Data_Bits --- Revise Data Bits for Communications    *)
(*----------------------------------------------------------------------*)

PROCEDURE Revise_Data_Bits;

VAR
   Bits_Menu   : Menu_Type;
   I           : INTEGER;
   Default     : INTEGER;

BEGIN (* Revise_Data_Bits *)
                                   (* Display menu and get choice *)

   IF Fixed_Entry.Phone_DataBits = '7' THEN
      Default := 1
   ELSE
      Default := 2;

   Make_And_Display_Menu( Bits_Menu, 2, 10, 30, 0, 0, Default,
                          'Data Bits in Each Character: ',
                          '7;8;',
                          FALSE, TRUE, I );

   IF ( I > 0 ) THEN
      Fixed_Entry.Phone_DataBits := CHR( ORD('6') + I );

END   (* Revise_Data_Bits *);

(*----------------------------------------------------------------------*)
(*        Revise_BackSpace --- Revise type of Backspace/Delete          *)
(*----------------------------------------------------------------------*)

PROCEDURE Revise_BackSpace;

VAR
   BS_Menu   : Menu_Type;
   I         : INTEGER;
   Default   : INTEGER;

BEGIN (* Revise_BackSpace *)
                                   (* Get current backspace setting *)

   IF ( Fixed_Entry.Phone_BackSpace = 'B' ) THEN
      Default := 1
   ELSE IF ( Fixed_Entry.Phone_BackSpace = 'D' ) THEN
      Default := 2
   ELSE
      Default := 3;
                                   (* Display menu and get choice *)

   Make_And_Display_Menu( BS_Menu, 3, 10, 30, 0, 0, Default,
                          'Backspace key sends: ',
                          'B)ackspace (ASCII 08);D)elete    (ASCII 127);' +
                          'U)se extant definition',
                          FALSE, TRUE, I );

   CASE I OF
      1: Fixed_Entry.Phone_BackSpace := 'B';
      2: Fixed_Entry.Phone_BackSpace := 'D';
      3: Fixed_Entry.Phone_BackSpace := ' ';
      ELSE;
   END (* CASE *);

END   (* Revise_BackSpace *);

(*----------------------------------------------------------------------*)
(*               Revise_Echo --- Revise local echo flag                 *)
(*----------------------------------------------------------------------*)

PROCEDURE Revise_Echo;

VAR
   Local_SaveIt : Saved_Screen_Ptr;
   Echo_Flag    : BOOLEAN;

BEGIN (* Revise_Name *)

   Draw_Titled_Box( Local_SaveIt, 10, 10, 65, 14, 'Local Echo' );

   PibTerm_Window( 11, 11, 64, 13 );

   GoToXY( 1 , 1 );

   Echo_Flag := YesNo('Set local echo (Y/N)? ');

   IF Echo_Flag THEN
      Fixed_Entry.Phone_Echo := 'Y'
   ELSE
      Fixed_Entry.Phone_Echo := 'N';

   Restore_Screen( Local_SaveIt );

END   (* Revise_Name *);

(*----------------------------------------------------------------------*)
(*                Revise_LineFeeds --- Revise CR/LF definition          *)
(*----------------------------------------------------------------------*)

PROCEDURE Revise_LineFeeds;

VAR
   LF_Menu   : Menu_Type;
   I         : INTEGER;
   Default   : INTEGER;

BEGIN (* Revise_LineFeeds *)
                                   (* Get CR/LF Key Use *)

   IF ( Fixed_Entry.Phone_LineFeed = 'Y' ) THEN
      Default := 2
   ELSE
      Default := 1;
                                   (* Display menu and get choice *)

   Make_And_Display_Menu( LF_Menu, 2, 10, 30, 0, 0, Default,
                          'Incoming carriage return acts like: ',
                          'CR only;CR + LF;',
                          TRUE, TRUE, I );

    CASE I OF
       1: Fixed_Entry.Phone_LineFeed := 'N';
       2: Fixed_Entry.Phone_LineFeed := 'Y';
       ELSE
    END (* CASE *);

END   (* Revise_LineFeeds *);

(*----------------------------------------------------------------------*)
(*        Revise_Terminal_Type --- Get Type of Terminal to Emulate      *)
(*----------------------------------------------------------------------*)

PROCEDURE Revise_Terminal_Type;

VAR
   Emul_Menu   : Menu_Type;
   I           : INTEGER;
   J           : INTEGER;
   Default     : INTEGER;

BEGIN (* Revise_Terminal_Type *)
                                   (* Get current terminal type *)

   CASE Fixed_Entry.Phone_Term_Type OF
      '0'..'9':  Default := ( ORD(Fixed_Entry.Phone_Term_Type) - ORD('0') ) + 2;
      'A'..'F':  Default := ( ORD(Fixed_Entry.Phone_Term_Type) - ORD('A') ) + 12;
      ELSE       Default := 1;
   END  (* CASE *);
                                   (* Construct and display menu *)

   Make_And_Display_Menu( Emul_Menu, NumberTerminalTypes + 2, 8, 30, 0, 0,
                          Default,
                          'Terminal to Emulate: ',
                          'None;Dumb;VT52;ANSI;VT100;Gossip Mode;Host Mode;' +
                          'Tektronix 4010;ADM3a;ADM5;TV925;User1;User2;User3;' +
                          'User4;User5;',
                          TRUE, TRUE, I );

                                   (* Handle choice *)
   IF ( I <= 1 ) THEN
      Fixed_Entry.Phone_Term_Type := ' '
   ELSE IF ( ( I > 1 ) AND ( I < 12 ) ) THEN
      Fixed_Entry.Phone_Term_Type := CHR( ORD( '0' ) + I - 2  )
   ELSE
      Fixed_Entry.Phone_Term_Type := CHR( ORD( 'A' ) + I - 12 );

END   (* Revise_Terminal_Type *);

(*----------------------------------------------------------------------*)
(*   Revise_Transfer_Protocol --- Revised protocol for file transfers   *)
(*----------------------------------------------------------------------*)

PROCEDURE Revise_Transfer_Protocol;

VAR
   Transfer_Kind : Transfer_Type;
   Default       : Transfer_Type;
   I             : INTEGER;

BEGIN (* Revise_Transfer_Protocol *)

                                   (* Get current transfer type *)
   Default := None;

   FOR I := 1 TO Max_Transfer_Types DO
      IF ( Fixed_Entry.Phone_Trans_Type = Trans_Type_Name[Transfers[I]] ) THEN
         Default := Transfers[I];

   Display_Transfer_Types( 'Default transfer protocol: ',
                           Default,
                           FALSE,
                           2, 30, 40, 0, 25,
                           TRUE,
                           Transfer_Kind );

   IF ( Transfer_Kind = None ) THEN
      Fixed_Entry.Phone_Trans_Type := '  '
   ELSE
      Fixed_Entry.Phone_Trans_Type := Trans_Type_Name[Transfer_Kind];

END   (* Revise_Transfer_Protocol *);

(*----------------------------------------------------------------------*)
(*        Revise_Script --- Revise script to execute when dialing       *)
(*----------------------------------------------------------------------*)

PROCEDURE Revise_Script;

VAR
   New_Script   : AnyStr;
   Local_SaveIt : Saved_Screen_Ptr;
   I            : INTEGER;
   J            : INTEGER;

LABEL 1;

BEGIN (* Revise_Script *)

   Draw_Titled_Box( Local_SaveIt, 10, 10, 65, 14, '' );

   PibTerm_Window( 11, 11, 64, 13 );

   TextColor( Menu_Text_Color_2 );

   GoToXY( 1 , 1 );

   New_Script := Fixed_Entry.Phone_Script;

   WRITELN('Old Script Name: ', New_Script );
   WRITE ('New Script Name: ');

   TextColor( Menu_Text_Color );

   Read_Edited_String( New_Script );

   IF ( ( LENGTH( New_Script ) <= 0 ) OR ( New_Script = CHR( ESC ) ) ) THEN
      New_Script := ' '
   ELSE
      BEGIN
                                   (* Now strip off directory stuff *)
                                   (* from script name itself.      *)
         I := POS( '.', New_Script );

                                   (* Remove trailing filetype      *)
         IF ( I > 0 ) THEN
            New_Script := COPY( New_Script, 1, I - 1 );

                                   (* Remove drive indicator        *)

         I := POS( ':', New_Script );

         IF ( I > 0 ) THEN
            New_Script := COPY( New_Script, I + 1, LENGTH( New_Script ) - I );

                                   (* Remove directory indicator *)

         IF ( POS( '\', New_Script ) > 0 ) THEN
            BEGIN
               J := LENGTH( New_Script );
               FOR I := J DOWNTO 1 DO
                  IF ( New_Script[I] = '\' ) THEN
                     BEGIN
                        New_Script := COPY( New_Script, I + 1 , J - I );
                        GOTO 1;
                     END;
            END;

      END;

1:
   CopySToA( New_Script , Fixed_Entry.Phone_Script , 9 );

   Restore_Screen( Local_SaveIt );

END   (* Revise_Script *);

(*----------------------------------------------------------------------*)

BEGIN (* Revise_Phone_Entry *)
                                   (* Get number to revise *)

   Draw_Titled_Box( Local_Save_2, 30, 10, 55, 14, 'Revise Dialing Entry');

   Quit := FALSE;
                                   (* Request the entry number *)

   TextColor( Menu_Text_Color_2 );

   WRITE('Entry to revise ? ');

   X       := WhereX;
   Y       := WhereY;
   SNumber := '';

   TextColor( Menu_Text_Color );

   Ch := Edit_String( SNumber, 30, X, X, Y, 30, FALSE, 0 );

                                   (* Exit if ESC entered *)

   IF ( Ch = CHR( ESC ) ) THEN
      BEGIN
         Restore_Screen( Local_Save_2 );
         EXIT;
      END;
                                   (* Take current entry if CR hit *)

   IF ( LENGTH( SNumber ) = 0 ) THEN
      J := Low_Num
   ELSE
      BEGIN

         J := 0;

         FOR X := 1 TO LENGTH( SNumber ) DO
            IF SNumber[X] IN ['0'..'9'] THEN
               J := J * 10 + ORD( SNumber[X] ) - ORD('0')
            ELSE
               BEGIN
                  WRITELN;
                  WRITELN('Invalid entry number.');
                  Window_Delay;
                  Restore_Screen( Local_Save_2 );
                  EXIT;
               END;

      END;

   IF ( ( J < 1 ) OR ( J > Dialing_Dir_Size ) ) THEN
      BEGIN
         WRITELN;
         WRITELN('No such entry.');
         Window_Delay;
         Restore_Screen( Local_Save_2 );
         EXIT;
      END
   ELSE                            (* Otherwise pick up entry's data *)
      BEGIN (* Entry exists *)

         Restore_Screen( Local_Save_2 );

         Fixed_Entry := Dialing_Directory^[ J ];

                                   (* Bring up revision window *)
         STR( J , S_No );
                                   (* Display items to revise *)

         Make_A_Menu( Revise_Menu, 14, 10, 30, 30, 0, 14,
                      'Revise Dialing Entry ' + S_No,
                      'All entries;Name;Number;Baud Rate;Parity;Data Bits;Stop Bits;' +
                      'Local Echo;Backspace;Add Linefeeds;Terminal Type;' +
                      'Transfer Type;Script Name;Quit;',
                      TRUE );

         Done        := FALSE;
         Revise_Item := 0;
         Changed_Any := FALSE;
                                   (* Select items to revise *)
         REPEAT

            Menu_Display_Choices( Revise_Menu );

            Revise_Item := Menu_Get_Choice( Revise_Menu , Erase_Menu );
            Changed_Any := Changed_Any OR ( Revise_Item <> 14 );

            CASE Revise_Item OF

               1:    BEGIN
                        Revise_Name;
                        Revise_Number;
                        Revise_Baud_Rate;
                        Revise_Data_Bits;
                        Revise_Parity;
                        Revise_Stop_Bits;
                        Revise_Echo;
                        Revise_BackSpace;
                        Revise_LineFeeds;
                        Revise_Terminal_Type;
                        Revise_Transfer_Protocol;
                        Revise_Script;
                        Done := TRUE;
                     END;
               2:    Revise_Name;
               3:    Revise_Number;
               4:    Revise_Baud_Rate;
               5:    Revise_Parity;
               6:    Revise_Data_Bits;
               7:    Revise_Stop_Bits;
               8:    Revise_Echo;
               9:    Revise_BackSpace;
               10:   Revise_LineFeeds;
               11:   Revise_Terminal_Type;
               12:   Revise_Transfer_Protocol;
               13:   Revise_Script;
               ELSE
                     Done := TRUE;

            END (* CASE *);

         UNTIL Done;
                                   (* Write revised entry back to *)
                                   (* phone directory file        *)
         IF Changed_Any THEN
            Update_Phone_File( Fixed_Entry, J );

      END (* Entry exists *);

END   (* Revise_Phone_Entry *);

