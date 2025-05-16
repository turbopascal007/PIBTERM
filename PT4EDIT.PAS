{.C-}
{.U Word}
{.U LongInt}
{.U UNIT}
{.U INTERFACE}
{.U USES}
{.U Dos}
{.U Crt}
{.U GlobType}
{.U StringMan}
{.U PibMTask}
{.U GlobRout}
{.U PibEditor}
{.U EditFileName}
{.U WriteSXY}
{.U Draw_Menu_Frame}
{.U Press_Any}
{.U PibTerm_Window}
{.U Dupl}
{.U Global_Text_Attribute}
{.U Global_ForeGround_Color}
{.U Global_BackGround_Color}
{.U Status_Line_Attr}
{.U Save_Partial_Screen}
{.U Restore_Screen}
{.U Do_Status_Time}
{.U Wait_For_Retrace}
{.U DesqView_Screen}
{.U TurnOnTimeSharing}
{.U TurnOffTimeSharing}
{.U MultiTasker}
{.U DoubleDos}
{.U Write_Screen_Memory}
{.U CRT_Status}
{.U Max_Screen_Col}
{.U TopView}
{.U Sync_Screen}
{.U Registers}
{.U Scroll}
{.U Set_Text_Attributes}
{.U EGA_Present}
{.U Extended_KeyBoard}
{.U UpperCase}
{.U Get_Screen_Address}
{.U AX}
{.U BX}
{.U CX}
{.U DX}
{.U AL}
{.U BL}
{.U CL}
{.U DL}
{.U AH}
{.U BH}
{.U CH}
{.U DH}
{.U INT24RESULT}
{.U Menu_Type}
{.U Saved_Screen_Ptr}
{.U Make_A_Menu}
{.U PibTerm_KeyPressed}
{.U Clear_Window}
{.U Menu_Display_Choices}
{.U Menu_Get_Choice}
{.U Read_Kbd}
{.U AnyStr}
{.U Save_Screen}
{.U Max_Screen_Line}
{.U Erase_Menu}
{.U MyFreeMem}
{.U WriteCXY}
{.U Menu_Frame_Color}
{.U Menu_Title_Color}
{.U Menu_Text_Color}

UNIT PT4EDIT;

INTERFACE

USES
   Dos, Crt, GlobType, StringMan, PibMTask, GlobRout;

PROCEDURE PibEditor( EditFileName : AnyStr );

IMPLEMENTATION
                                   (* Editor globals *)
{.C+}
{$I PIBEDITR.GLO }
{.C-}
                                   (* Editor code    *)
                                   
(*----------------------------------------------------------------------*)
(*           PibEditor --- Simple screen editor for PibTerm             *)
(*----------------------------------------------------------------------*)

PROCEDURE PibEditor( EditFileName : AnyStr );

VAR
   Local_Save   : Saved_Screen_Ptr;
   Local_Save_2 : Saved_Screen_Ptr;
   Name_Given   : BOOLEAN;
   
PROCEDURE Editor( EditFileName : AnyStr );

{.C+}
{$I editsub1.mod }
{$I editsub2.mod }
PROCEDURE II1III111II1(II1II1II1I:AnyStr);VAR III11I:INTEGER;III1II1I11:INTEGER;BEGIN III11I:=WHEREX
;III1II1I11:=(Status_Line_Attr AND $F0) OR WHITE;WriteCXY(II1II1II1I[1],III11I,Max_Screen_Line,
III1II1I11);WriteSXY(COPY(II1II1II1I,2,80),SUCC(III11I),Max_Screen_Line,Status_Line_Attr);GOTOXY(
III11I+LENGTH(II1II1II1I),Max_Screen_Line);END;PROCEDURE II111I;BEGIN PibTerm_Window(1,1,
Max_Screen_Col,Max_Screen_Line);WriteSXY(I1IIII11I1111,1,Max_Screen_Line,Status_Line_Attr);
II1III111II1('1Help ');II1III111II1('2Undo ');II1III111II1('3Find ');II1III111II1('4Replace ');
II1III111II1('5SaveQuit ');II1III111II1('6InsLine ');II1III111II1('7DelLine ');II1III111II1(
'8Startblk ');II1III111II1('9Endblk ');II1III111II1('0Quit');END;PROCEDURE I1II1I1II(IIII111I1:
AnyStr);BEGIN Draw_Menu_Frame(5,10,75,14,Menu_Frame_Color,Menu_Title_Color,Menu_Text_Color,'');
GOTOXY(1,1);WRITELN(IIII111I1);Press_Any;END;VAR IIIIIII1II1I1:I11I1I11;I1I1II11I1:INT;II1111II1:
II1II1I1I;I111111I1I1:ARRAY[0..10] OF INT;IIIII111111I:LongInt;II111II1:Word;BEGIN I1III1II:=
Global_Text_Attribute;I111IIII:=(Global_ForeGround_Color AND 7) SHL 4+(Global_BackGround_Color);
III11III:=Status_Line_Attr;III111I1I:=Status_Line_Attr;I1IIII11I1111:=Dupl(' ',Max_Screen_Col);
II1111II1:=EditFileName;IIIII111111I:=MAXAVAIL;IF (IIIII111111I>$FFE0) THEN II111II1:=$FFE0 ELSE 
II111II1:=IIIII111111I;I1I1II11I1:=III1III1II1I(IIIIIII1II1I1,II111II1,1,1,Max_Screen_Col,
Max_Screen_Line,Wait_For_Retrace,'');IF (I1I1II11I1<>0) THEN BEGIN I1II1I1II(
'Not enough memory to perform editing.');EXIT;END;I1I1II11I1:=II1I111111I(IIIIIII1II1I1,II1111II1);
CASE I1I1II11I1 OF II:BEGIN Save_Partial_Screen(Local_Save_2,5,10,75,14);I1II1I1II(
'File to be edited not found, new file will be created.');Restore_Screen(Local_Save_2);II1I11I1III(
IIIIIII1II1I1,II1111II1);END;II111II111:BEGIN I1II1I1II(
'I/O error occurred while reading file, editing cancelled.');EXIT;END;I1I111I1I:BEGIN I1II1I1II(
'File is too big to be edited, editing cancelled.');EXIT;END;ELSE;END;I111111I1I1[0]:=1;I111111I1I1[1
]:=68;I111111I1I1[2]:=0;II111I;I1I1II11I1:=I1I11I1111I1(IIIIIII1II1I1,1,1,Max_Screen_Col,PRED(
Max_Screen_Line),I1I11II1I,0,0,I111111I1I1);IF (I1II1I111II11(IIIIIII1II1I1) AND (I1I1II11I1=0)) 
THEN BEGIN I1I1II11I1:=II1I1II1(IIIIIII1II1I1);IF I1I1II11I1<>0 THEN I1II1I1II(
'I/O error while writing edited file.');END;II1III1I(IIIIIII1II1I1);III1IIII1(1,1,Max_Screen_Col,
Max_Screen_Line);II1II111I1I(1,Max_Screen_Line);END;{.C-}

(*----------------------------------------------------------------------*)
(*           PibEditor --- Main program to get file name for editing    *)
(*----------------------------------------------------------------------*)

BEGIN (* PibEditor *)
                                   (* Don't update status Line *)
                                   
   Save_Do_Status_Time := Do_Status_Time;
   Do_Status_Time      := FALSE;
   
                                   (* Save screen *)
                                   
   Draw_Titled_Box( Local_Save, 5, 10, 75, 14, 'Edit File' );
   
                                   (* Get name of file to edit *)
                                   
   Name_Given   := ( LENGTH( EditFileName ) > 0 );

   TextColor( Menu_Text_Color_2 );
   WRITELN('Enter name of file to edit: ');
   WRITE('>');
   
   TextColor( Menu_Text_Color );
   
   IF ( NOT Name_Given ) THEN
      Read_Edited_String( EditFileName )
   ELSE
      WRITE( EditFileName );
   WRITELN;
                                   (* Restore screen *)
                                   
   Restore_Screen_And_Colors( Local_Save );
   
                                   (* Save screen *)
                                   
   IF ( ( EditFileName <> CHR( ESC ) ) AND
        ( EditFileName <> ''         ) ) THEN
      BEGIN
      
         Save_Screen( Local_Save );
                                   (* Edit the file *)
         Editor( EditFileName );
                                   (* Restore screen *)
                                   
         Restore_Screen_And_Colors( Local_Save );
         
      END;
                                   (* Restore status Line check *)
                                   
   Do_Status_Time := Save_Do_Status_Time;
   
END   (* PibEditor *);

END   (* PT4EDIT *).
