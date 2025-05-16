(*----------------------------------------------------------------------*)
(*             List_One_File --- List one file                          *)
(*----------------------------------------------------------------------*)

PROCEDURE List_One_File( View_File_Name : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Procedure:   List_One_File                                         *)
(*                                                                      *)
(*   Purpose:     Lists one file                                        *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      List_One_File( Dir_Entry : SearchRec );                         *)
(*                                                                      *)
(*         Dir_Entry --- Directory record of file to be listed.         *)
(*                                                                      *)
(*   Calls:  Init_This_File                                             *)
(*           Display_Screen                                             *)
(*           Prompt                                                     *)
(*                                                                      *)
(*   Remarks:                                                           *)
(*                                                                      *)
(*      This routine controls the listing of one file.                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   Max_String    = 255        (* max string length             *);
   FF            = #12        (* form feed character           *);
   TAB           = #9         (* tab character                 *);
   CR            = #13        (* carriage return character     *);
   LF            = #10        (* line feed character           *);
   ESC           = #27        (* escape character              *);
   NUL           = #0         (* null character                *);

TYPE

   Line_Ptr = ^Line            (* pointer to text line           *);

   Line =                      (* text line                      *)
      RECORD
         Next: Line_Ptr        (* pointer to next line in buffer *);
         Lnum: LONGINT         (* line number                    *);
         Pnum: LONGINT         (* page number                    *);
         Txt:  AnyStr          (* text Line                      *);
      END;

VAR

   F            : TEXT               (* file to be listed                     *);
   First        : Line_Ptr           (* pointer to first line in buffer       *);
   Last         : Line_Ptr           (* pointer to last line in buffer,       *)
                                     (* or nil if buffer empty                *);
   PS_Size      : INTEGER            (* Physical screen size                  *);
   Height       : INTEGER            (* List window height                    *);
   Top          : Line_Ptr           (* pointer to top line in viewing window *);
   Bot          : Line_Ptr           (* pointer to bottom line in viewing     *)
                                     (* window                                *);
   Cur_Line     : LONGINT            (* line number of next line on file f    *);
   Max_Line     : LONGINT            (* max line number seen so far           *);
   First_Col    : INTEGER            (* first col to be displayed             *);
   Width        : INTEGER            (* screen width                          *);
   Done         : BOOLEAN            (* TRUE when one file finished           *);
   All_Done     : BOOLEAN            (* TRUE if all selected files listed     *);
   Eod          : BOOLEAN            (* TRUE if requested line or page        *)
                                     (* is beyond end of file f               *);
   EOF_Seen     : BOOLEAN            (* TRUE if eof reached                   *);
   Top_Line     : LONGINT            (* line number of top line on currently  *)
                                     (* displayed screen                      *);
   One_Up       : BOOLEAN            (* If command is move up one line        *);
   One_Down     : BOOLEAN            (* If command is move down one line      *);

   Search_Str   : AnyStr             (* String to look for with search comm.  *);
   Search_Lpos  : INTEGER            (* Screen position of line containing    *)
                                     (* searched string                       *);
   Search_Line  : LONGINT            (* Line number of line containing        *)
                                     (* searched string                       *);
   Search_Col   : INTEGER            (* Position of searched string in line   *);
   Search_Exact : BOOLEAN            (* TRUE to do exact match in search      *);

                                     (* Unprintable characters                *)

   Spec_Chars   : ARRAY[CHAR] OF BOOLEAN;

   Strip_High   : BOOLEAN            (* TRUE to strip high-order bits         *);
   Expand_Tabs  : BOOLEAN            (* TRUE to expand horizontal tabs        *);

   File_Spec    : AnyStr            (* Full path name of file being listed   *);
   File_Pattern : AnyStr            (* Wildcard for files to list            *);
   Dir_Entry    : SearchRec         (* Directory info for current file       *);

   Max_Buf_Lines     : INTEGER      (* Max number of lines in buffer *);

   Normal_Color      : INTEGER;
   Search_Color      : INTEGER;
   Status_Line_Color : INTEGER;
   Spec_Chars_Color  : INTEGER;
   Help_Text_Color   : INTEGER;
   Spec_Chars_Color_2: INTEGER;

(*----------------------------------------------------------------------*)
(*               Rmin --- Find minimum of two long integers             *)
(*----------------------------------------------------------------------*)

FUNCTION Rmin( A, B: LONGINT ) : LONGINT;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Function: Rmin                                                     *)
(*                                                                      *)
(*   Purpose:  Returns smaller of two long integer numbers              *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      Smaller := RMIN( A , B : LONGINT ) : LONGINT;                   *)
(*                                                                      *)
(*         A       --- 1st input long integer number                    *)
(*         B       --- 2nd input long integer number                    *)
(*         Smaller --- smaller of A, B returned                         *)
(*                                                                      *)
(*                                                                      *)
(*   Calls:  None                                                       *)
(*                                                                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Rmin *)

   IF A < B THEN
      Rmin := A
   ELSE
      Rmin := B;

END   (* Rmin *);

(*----------------------------------------------------------------------*)
(*               Rmax --- Find maximum of two long integers             *)
(*----------------------------------------------------------------------*)

FUNCTION Rmax( A, B: LONGINT ) : LONGINT;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Function:  Rmax                                                    *)
(*                                                                      *)
(*   Purpose:   Returns larger of two long integer numbers              *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      Larger := RMAX( A , B : LONGINT ) : LONGINT;                    *)
(*                                                                      *)
(*         A       --- 1st input long integer number                    *)
(*         B       --- 2nd input long integer number                    *)
(*         Larger  --- Larger of A, B returned                          *)
(*                                                                      *)
(*                                                                      *)
(*   Calls:  None                                                       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Rmax *)

   IF A > B THEN
      Rmax := A
   ELSE
      Rmax := B;

END   (* Rmax *);

(*----------------------------------------------------------------------*)
(*        Reset_F:  Reposition file to beginning of information         *)
(*----------------------------------------------------------------------*)

PROCEDURE Reset_F;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Procedure:   Reset_F                                               *)
(*                                                                      *)
(*   Purpose:     Resets file being listed to beginning of information. *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      Reset_F;                                                        *)
(*                                                                      *)
(*   Calls:  Reset                                                      *)
(*                                                                      *)
(*   Remarks:                                                           *)
(*                                                                      *)
(*      Cur_Line is reset to 1 here.                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN  (* Reset_F *)

   RESET( F );

   Cur_Line := 1;

END    (* Reset_F *);

(*----------------------------------------------------------------------*)
(*                Readln_F:  Read a line from the file F                *)
(*----------------------------------------------------------------------*)

PROCEDURE Readln_F;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Procedure:   Readln_F                                              *)
(*                                                                      *)
(*   Purpose:     Read a line from the file F                           *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      Readln_F;                                                       *)
(*                                                                      *)
(*   Calls:  None                                                       *)
(*                                                                      *)
(*   Remarks:                                                           *)
(*                                                                      *)
(*      EOF( F ) MUST be FALSE on entry, but may be TRUE on exit.       *)
(*      Cur_Line and Max_Line are updated.                              *)
(*                                                                      *)
(*      Note:  The input buffer for file F is used to "peek" at         *)
(*             the next character.  This corresponds to looking at      *)
(*             F^ in standard Pascal.                                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Readln_F *)
                                   (* Reset F to beginning of next  *)
                                   (* line.                         *)
   IF ( NOT Strip_High ) THEN
      READLN( F );
                                   (* Update current line           *)
   INC( Cur_Line );

   Max_Line := RMax( Cur_Line , Max_Line );

END   (* Readln_F *);

(*----------------------------------------------------------------------*)
(*              Clear_Buffer -- Clears buffer of saved lines            *)
(*----------------------------------------------------------------------*)

PROCEDURE Clear_Buffer;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Procedure:   Clear_Buffer                                          *)
(*                                                                      *)
(*   Purpose:     Clears buffer of saved lines.                         *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      Clear_Buffer;                                                   *)
(*                                                                      *)
(*   Calls:  None                                                       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN  (* Clear_Buffer *)

   Last := NIL;

END    (* Clear_Buffer *);

(*----------------------------------------------------------------------*)
(*              Skip_To_Line --- Skips to specified line in file F      *)
(*----------------------------------------------------------------------*)

PROCEDURE Skip_To_Line( N : LONGINT );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Procedure:   Skip_To_Line                                          *)
(*                                                                      *)
(*   Purpose:     Skips forward to specified line on file F.            *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      Skip_To_Line( N : LONGINT );                                    *)
(*                                                                      *)
(*         N  --- line to skip to                                       *)
(*                                                                      *)
(*   Calls:  Readln_F                                                   *)
(*                                                                      *)
(*   Remarks:                                                           *)
(*                                                                      *)
(*      Line  N  must exist.  File F must also be positioned at or      *)
(*      before line  N.  On exit file F is positioned at line  N.       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN  (* Skip_To_Line *)

   WHILE ( Cur_Line < N ) DO
      Readln_F;

END    (* Skip_To_Line *);

(*----------------------------------------------------------------------*)
(*              Scan_To_EOF  -- Scan forward to end of file on F        *)
(*----------------------------------------------------------------------*)

PROCEDURE Scan_To_EOF;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Procedure:   Scan_To_EOF                                           *)
(*                                                                      *)
(*   Purpose:     Skips forward to end of file on file F.               *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      Scan_To_EOF;                                                    *)
(*                                                                      *)
(*   Calls:  Readln_F                                                   *)
(*           Reset_F                                                    *)
(*                                                                      *)
(*   Remarks:                                                           *)
(*                                                                      *)
(*      On entry EOF_Seen = FALSE.  On exit EOF_Seen = TRUE, Max_Line = *)
(*      the largest line number on the file.  F is also reset on exit.  *)
(*      This routine is called for large forward skips by the Find_Line *)
(*      routine.  It is called AT MOST ONCE per viewing of a file.      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN  (* Scan_To_EOF *)

   WHILE ( NOT EOF( F ) ) DO
      Readln_F;

   EOF_Seen := TRUE;
   Reset_F;

END    (* Scan_To_EOF *);

(*----------------------------------------------------------------------*)
(*                  Read_Line --- read line from file F                 *)
(*----------------------------------------------------------------------*)

PROCEDURE Read_Line;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Procedure:   Read_Line                                             *)
(*                                                                      *)
(*   Purpose:     Reads next line from file F and appends it to buffer. *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      Read_Line;                                                      *)
(*                                                                      *)
(*   Remarks:                                                           *)
(*                                                                      *)
(*     If the buffer is full the first Line in the buffer               *)
(*     is deleted to make room.  This operation "slides the buffer      *)
(*     forward" one line on the file.  If EOF(F)  is TRUE on entry      *)
(*     then no line is read, and Eof_Seen is set TRUE.  Tabs are        *)
(*     expanded, if Expands_Tabs is TRUE.  If the high-order bits are   *)
(*     to be stripped then the read is done character by character to   *)
(*     avoid problems with "disguised" carriage returns.   On entry F   *)
(*     must be positioned at EOF or at the beginning of a line.  On     *)
(*     exit F is left positioned at EOF or at the beginning of the next *)
(*     line.                                                            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Line:    STRING[Max_String];
   Inlen:   INTEGER;
   C:       CHAR;
   I:       INTEGER;
   J:       INTEGER;
   N:       INTEGER;
   LTxt:    INTEGER;

BEGIN (* Read_Line *)

   IF ( NOT EOF( F ) ) THEN
      BEGIN
                                   (* Figure position in line buffer *)
         IF ( Last = NIL ) THEN
            Last := First
         ELSE
            BEGIN
               Last := Last^.Next;
               IF ( Last = First ) THEN
                  First := First^.Next
            END;

         WITH Last^ DO
            BEGIN
                                   (* Remember line number of this line *)
               Lnum := Cur_Line;
                                   (* Get text of line.                 *)
                                   (* If bit-stripping, check on a      *)
                                   (* character by character basis for  *)
                                   (* CR/LF combinations.               *)

               IF ( NOT Strip_High ) THEN
                  READ( F , Txt )
               ELSE
                  BEGIN

                     Txt  := '';
                     LTxt := 0;

                     READ( F , C );

                     C := CHR( ORD( C ) AND $7F );

                     WHILE ( C <> CR ) DO
                        BEGIN
                           INC( LTxt );
                           Txt[LTxt] := C;
                           READ( F , C );
                           C  := CHR( ORD( C ) AND $7F );
                        END;

                     READ( F , C );

                     Txt[0] := CHR( LTxt );

                  END;

                                   (* Expand tabs if requested          *)
               IF Expand_Tabs THEN
                  BEGIN

                     Line    := Txt;
                     Txt     := '';
                     LTxt    := 0;

                     Inlen   := LENGTH( Line );

                     I := 0;
                     J := 0;

                     WHILE ( ( J < Inlen ) AND ( I < Max_String ) ) DO
                        BEGIN

                           INC( J );

                           C := Line[J];

                           IF ( C = TAB ) THEN
                              BEGIN

                                 N := 8 - ( I MOD 8 );

                                 WHILE ( I < Max_String ) AND ( N > 0 ) DO
                                    BEGIN
                                       INC(  I   );
                                       INC( LTxt );
                                       Txt[ LTxt ] := ' ';
                                       DEC( N    );
                                    END;

                              END
                           ELSE
                              BEGIN
                                 INC( LTxt );
                                 Txt[ LTxt ] := C;
                              END;

                        END (* While *);

                     Txt[0] := CHR( LTxt );

                  END (* IF Expand_Tabs *);

            END  (* With Last^ *) ;

         Readln_F;

      END

   ELSE
      Eof_Seen := TRUE;

END   (* Read_Line *);

(*----------------------------------------------------------------------*)
(*                  Get_Search_String --- Get string to search for      *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Search_String;

VAR
   Local_Save : Saved_Screen_Ptr;

BEGIN (* Get_Search_String *)

   Search_Exact := FALSE;
   Search_Lpos  := 0;
   Search_Line  := 0;

   Draw_Titled_Box( Local_Save, 10, 10, 65, 14, 'Search for string');

   TextColor( Menu_Text_Color_2 );

   CursorOn;

   GoToXY( 1 , 1 );
   WRITE('String to search for? ');

   TextColor( Menu_Text_Color );

   Read_Edited_String( Search_Str );

   IF ( NOT Search_Exact ) THEN
      Search_Str := UpperCase( Search_Str );

   Restore_Screen( Local_Save );

   CursorOff;

END   (* Get_Search_String *);

(*----------------------------------------------------------------------*)
(*                  Get_Line_Number --- Get line number to search for   *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Line_Number( VAR LineNo : LONGINT );

VAR
   Local_Save  : Saved_Screen_Ptr;
   N           : LongInt;
   B           : BOOLEAN;

BEGIN (* Get_Line_Number *)

   Draw_Titled_Box( Local_Save, 10, 10, 65, 14, 'Jump to line');

   TextColor( Menu_Text_Color_2 );

   CursorOn;

   GoToXY( 1 , 1 );
   WRITE('Line number to jump to? ');

   TextColor( Menu_Text_Color );

   IF ( NOT Read_Number( 0, FALSE, LineNo ) ) THEN
      LineNo := -1;

   Restore_Screen( Local_Save );

   CursorOff;

END   (* Get_Search *);

(*----------------------------------------------------------------------*)
(*                  Find_Line --- Find line on file F                   *)
(*----------------------------------------------------------------------*)

PROCEDURE Find_Line( N : LONGINT );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Procedure:   Find_Line                                             *)
(*                                                                      *)
(*   Purpose:     Finds and moves to specified line on file F           *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      Find_Line( N : LONGINT );                                       *)
(*                                                                      *)
(*         N --- line to be found                                       *)
(*                                                                      *)
(*   Calls:  Read_Line                                                  *)
(*           RMIN                                                       *)
(*           Clear_Buffer                                               *)
(*           Skip_To_Line                                               *)
(*           Reset_F                                                    *)
(*           Scan_To_Eof                                                *)
(*                                                                      *)
(*   Remarks:                                                           *)
(*                                                                      *)
(*      On exit Eod=TRUE if the line does not exist.  In this case the  *)
(*      buffer is full and it contains the lines at end of the file.    *)
(*      Otherwise Eod=FALSE, line n is in the buffer, and top points    *)
(*      to it.                                                          *)
(*                                                                      *)
(*      The algorithm divides into three cases.                         *)
(*                                                                      *)
(*      Case 1.  The line preceeds the buffer.  In this case the file   *)
(*      is reset and the buffer is cleared.  The goal is to exit        *)
(*      with the buffer full and with line n at the end of the buffer.  *)
(*      This is accomplished by skipping the proper number of lines,    *)
(*      then reading lines into the buffer until line n has been        *)
(*      reached.                                                        *)
(*                                                                      *)
(*      Case 2.  The line is inside the buffer.  A simple linear search *)
(*      of the buffer locates the requested line.                       *)
(*                                                                      *)
(*      Case 3.  The line follows the buffer.  This is the complicated  *)
(*      case.  As in case 1, the goal is to exit with a full buffer     *)
(*      and with line n at the end of the buffer.  However, if line n   *)
(*      does not exist then we want to exit with a full buffer          *)
(*      consisting of the lines at the end of the file.  For efficiency *)
(*      in large forward skips, we don't want to simply read lines into *)
(*      the buffer until line n or eof is encountered.  Skipping is     *)
(*      faster than reading, so we'd prefer to skip lines, then read a  *)
(*      full buffer's worth.  The problem is to determine how many      *)
(*      lines to skip.                                                  *)
(*                                                                      *)
(*      (a) If line n is within Max_Buf_Lines of the Last line in the   *)
(*          buffer then no lines are skipped.  Lines are simply read    *)
(*          into the buffer until line n or eof is reached.  This is    *)
(*          a "short" forwards skip.                                    *)
(*                                                                      *)
(*      (b) Assume (a) doesn't hold.  If n is less than or equal to the *)
(*          maximum line number seen so far then we know that line n    *)
(*          must exist.  In this case we skip to line (n-Max_Buf_Lines),*)
(*          then read lines into the buffer until line n is reached.    *)
(*                                                                      *)
(*      (c) Assume neither (a) nor (b) holds.  If we have earlier       *)
(*          encountered eof on file f, then Max_Line is the largest     *)
(*          line number on the file, and we know whether or not line    *)
(*          n exists.  In this case we skip to line min(n,Max_Line) -   *)
(*          Max_Buf_Lines, and then read lines into the buffer until    *)
(*          either line n or eof is reached.                            *)
(*                                                                      *)
(*      (d) If none of cases (a), (b) or (c) hold then we scan to       *)
(*          eof to determine whether or not line n exists.  Max_Line    *)
(*          is now the largest line number on the file.  File f is      *)
(*          reset, and we proceed as in case (c).  Note that this case  *)
(*          can occur at most once per run of the viewer.               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   M : LONGINT;

BEGIN  (* Find_Line *)

   Eod := FALSE;
                                   (* Case 1 *)
   IF ( N < First^.LNum ) THEN
      BEGIN

         Reset_F;

         Clear_Buffer;

         IF ( N > Max_Buf_Lines ) THEN
            Skip_To_Line( N - Max_Buf_Lines );

         REPEAT
            Read_Line;
         UNTIL ( Last^.LNum = N );

         Top := Last;

      END                          (* Case 2 *)
   ELSE IF ( N <= Last^.LNum ) THEN
      BEGIN

         Top := First;

         WHILE ( Top^.LNum < N ) DO Top := Top^.Next;

      END
   ELSE
      BEGIN                        (* Case 3 *)

         IF ( ( NOT EOF_Seen ) AND ( ( N - Max_Buf_Lines ) > Last^.LNum )
            AND ( N > Max_Line ) ) THEN
               Scan_To_Eof;

         M := RMIN( N , Max_Line ) - Max_Buf_Lines;

         IF ( M > Last^.LNum ) THEN
            BEGIN
               Clear_Buffer;
               Skip_To_Line( M )
            END;

         REPEAT
            Read_Line;
         UNTIL ( ( Last^.LNum = N ) OR EOF( F ) );

         Top := Last;
         Eod := ( Top^.LNum < N );

      END;

END   (* Find_Line *);

(*----------------------------------------------------------------------*)
(*           Find_String --- Find next occurrence of string on F        *)
(*----------------------------------------------------------------------*)

PROCEDURE Find_String( S: AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Procedure:   Find_String                                           *)
(*                                                                      *)
(*   Purpose:     Find next occurrence of string on F                   *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      Find_String( S: AnyStr );                                       *)
(*                                                                      *)
(*         S --- String to be found                                     *)
(*                                                                      *)
(*   Calls:  Read_Line                                                  *)
(*           Find_Line                                                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Found:  BOOLEAN;
   Done:   BOOLEAN;
   LineNo: INTEGER;
   N:      INTEGER;

LABEL 1;

BEGIN  (* Find_String *)

   Found       := FALSE;
   Done        := FALSE;

   Search_Lpos := 0;
   Search_Col  := 0;

   REPEAT

      Bot    := Top;
      LineNo := 0;
      N      := Height;

      WHILE ( ( N > 0 ) AND ( NOT Eod ) ) DO
         BEGIN

            INC( LineNo );

            IF Search_Exact THEN
               Search_Col := POS( Search_Str , Bot^.Txt )
            ELSE
               Search_Col := POS( Search_Str , UpperCase( Bot^.Txt ) );

            IF ( Search_Col <> 0 ) THEN
               BEGIN
                  Search_Lpos := LineNo;
                  Search_Line := Bot^.Lnum;
                  Found       := TRUE;
                  GOTO 1;
               END;

            DEC( N );

            IF ( N > 0 ) THEN
               IF ( Bot = Last ) THEN
                  BEGIN
                     Read_Line;
                     Eod := EOF( F );
                     Bot := Last;
                  END
               ELSE
                  Bot := Bot^.Next;

         END;

      Done := ( N > 0 );

      IF ( NOT Done ) THEN
         Find_Line( Top^.LNum + Height );

1:
   UNTIL ( Found OR Done );

END    (* Find_String *);

