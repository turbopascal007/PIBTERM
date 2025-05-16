PROCEDURE Test_Version_Warning;

VAR
   Ch: CHAR;

BEGIN (* Test_Version_Warning *)
{
   Do_Status_Line   := FALSE;
   Do_Status_Time   := FALSE;

   TextColor     ( WHITE );
   TextBackGround( BLACK );

   WRITELN;
   WRITELN('***** WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING *****');
   WRITELN('*                                                                         *');
   WRITELN('*     This is a TEST VERSION of PibTerm, NOT a production version.        *');
   WRITELN('*     Please report problems to:                                          *');
   WRITELN('*                                                                         *');
   WRITELN('*          Philip R. Burns                                                *');
   WRITELN('*          Vogelback Computing Center                                     *');
   WRITELN('*          Northwestern University                                        *');
   WRITELN('*          2129 Sheridan Road                                             *');
   WRITELN('*          Evanston, IL.  60208                                           *');
   WRITELN('*                                                                         *');
   WRITELN('*     You may also find out about the most recent production of           *');
   WRITELN('*     PibTerm by writing to the same address.                             *');
   WRITELN('*                                                                         *');
   WRITELN('*     NO PHONE CALLS PLEASE!                                              *');
   WRITELN('*                                                                         *');
   WRITELN('***** WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING *****');
   WRITELN;

   IF ( ParamCount = 0 ) THEN
      BEGIN

         WRITE('Hit any key to continue ... ');

         Read_Kbd( Ch );
         IF ( ORD( Ch ) = ESC ) AND PibTerm_KeyPressed THEN
            Read_Kbd( Ch );

      END
   ELSE
      DELAY( Two_Second_Delay );
}
END   (* Test_Version_Warning *);
