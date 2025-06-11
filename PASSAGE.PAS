{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/passage)
  @abstract(Target: Free Pascal)
}

Program PASSAGE;

{$mode objfpc}

Uses
 DOS,fphttpclient,OpenSSLSockets,SysUtils;

Var
 Client:TFPHTTPClient;
 InPacket,PacketFound:Boolean;
 PacketName,CommandLine,CommandParam:String;
 URL,CurrLine,Response:AnsiString;
 PacketFile:Text;

Function StrToUpper(S:String):String;
Var
 I:Byte;
Begin
 For I:=1 to Length(S)do Begin
  If S[I] in['a'..'z']Then S[I]:=Chr(Ord(S[I])-32);
 End;
 StrToUpper:=S;
End;

Function StrReplace(Source,Old,New:String):String;
Var
 P:LongInt;
Begin
 While Pos(Old,Source)<>0 do Begin
  P:=Pos(Old,Source);
  Delete(Source,P,Length(Old));
  Insert(New,Source,P);
 End;
 StrReplace:=Source;
End;

Function SplitFileName(s:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Splitfilename:=N+E;
End;

Function GetCurrentDir:String;
Var
 S:String;
Begin
 GetDir(0,S);
 GetCurrentDir:=S;
End;

Procedure DownloadFileURL(URL:String);
Var
 Client:TFPHTTPClient;
 FileName:String;
 Response:AnsiString;
 FileDownload:Text;
Begin
 FileName:=SplitFileName(URL);
 Client:=TFPHTTPClient.Create(nil);
 Try
  Client.AllowRedirect:=True;
  Response:=Client.SimpleGet(URL);
 Except
   On E: Exception do
    Writeln('Erreur: ', E.Message);
  End;
 Client.Free;
 {$I-}Assign(FileDownload,FileName);
 Rewrite(FileDownload);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible d''‚crire le fichier : ',FileName);
  Halt(1);
 End;
 Writeln(FileDownload,Response);
 Close(FileDownload);
End;

Function ParseCommandLine(Const CommandLine:String;Var Commande,Parametres:String):Boolean;
Var
 I:Integer;
 InQuotes:Boolean;
 CmdEndPos:Integer;
Begin
 Commande:='';
 Parametres:='';
 Result:=FALSE;
 I:=1;
 While(I<=Length(CommandLine))and(CommandLine[I] = ' ')do Inc(I);
 If I>Length(CommandLine)Then Exit;
 CmdEndPos:=I;
 InQuotes:=False;
 If CommandLine[I]='"'Then Begin
  InQuotes:=True;
  Inc(I);
  CmdEndPos:=I;
  While(I<=Length(CommandLine))and(CommandLine[I]<>'"')do Begin
   Inc(I);
  End;
  If(I<=Length(CommandLine))and(CommandLine[I]='"')Then Begin
   Commande:=Copy(CommandLine,CmdEndPos,I-CmdEndPos);
   Inc(I);
   Result:=True;
  End
   Else
  Begin
   Commande:=Copy(CommandLine,CmdEndPos,Length(CommandLine)-CmdEndPos+1);
   Result:=False;
   Exit;
  End;
 End
  Else
 Begin
  While(I<=Length(CommandLine))and(CommandLine[I]<>' ')do Begin
   Inc(I);
  End;
  Commande:=Copy(CommandLine,CmdEndPos,I-CmdEndPos);
  Result:=True;
 End;
 If Result Then Begin
  While(I<=Length(CommandLine))and(CommandLine[I]=' ')do Inc(I);
  If I<=Length(CommandLine)Then
   Parametres:=Copy(CommandLine,I,Length(CommandLine)-I+1);
  END;
END;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('PASSAGE : Cette commande permet de lancer le gestionnaire de ');
  WriteLn('       paquet Pascal (PasSage).');
  WriteLn;
  WriteLn('Syntaxe : PASSAGE nomdupaquet');
  WriteLn;
  WriteLn(' nomdupaquet Ce paramŠtre permet d''indiquer le nom du paquet … t‚l‚charger.');
  WriteLn(' --help     Ce paramŠtre permet de retourner de l''aide sur cette commande');
  WriteLn(' --version  Ce paramŠtre permet de retourner la version de la commande');
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('PASSAGE 0.2 - PasSage de passage ou corail');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('crit par Sylvain Maltais');
 End
  Else
 Begin
  URL:='https://raw.githubusercontent.com/gladir/passage/refs/heads/main/LIST/list.001';
  PacketName:=ParamStr(1);
  If PacketName=''Then Begin
   WriteLn('Un nom de paquet est requis comme paramŠtre !');
   Halt(1);
  End;
   { Cr‚e une instance de TFPHTTPClient }
  Client:=TFPHTTPClient.Create(nil);
  Try
    {Cr‚e le fichier de liste }
   Response:=Client.SimpleGet(URL);
   {$I-}Assign(PacketFile,'list.tmp');
   Rewrite(PacketFile);{$I+}
   If IOResult<>0 Then Begin
    WriteLn('Impossible d''‚crire les donn‚es temporaires');
    Halt(1);
   End;
   Writeln(PacketFile,Response);
   Close(PacketFile);
    {Lit le fichier de liste }
   {$I-}Assign(PacketFile,'list.tmp');
   Reset(PacketFile);{$I+}
   If IOResult<>0 Then Begin
    WriteLn('Impossible de lire les donn‚es temporaires');
    Halt(1);
   End;
   InPacket:=False;
   PacketFound:=False;
   While Not EOF(PacketFile)do Begin
    ReadLn(PacketFile,CurrLine);
    If CurrLine<>''Then Begin
     If StrToUpper(CurrLine)='['+StrToUpper(PacketName)+']'Then Begin
      InPacket:=True;
      PacketFound:=True;
     End
      Else
     If Copy(CurrLine,1,1)='['Then InPacket:=False Else
     If(InPacket)Then Begin
      If StrToUpper(Copy(CurrLine,1,Length('TITLE:')))='TITLE:'Then Begin
       WriteLn('Nom : ',Copy(CurrLine,Length('TITLE:')+2));
      End
       Else
      If StrToUpper(Copy(CurrLine,1,Length('MAKE:')))='MAKE:'Then Begin
       ParseCommandLine(Copy(CurrLine,Length('MAKE:')+2,255),CommandLine,CommandParam);
       CommandParam:=StrReplace(CommandParam,'%cd%',GetCurrentDir);
       ExecuteProcess(CommandLine,CommandParam);
      End
       Else
      Begin
       WriteLn('T‚l‚chargement de ',CurrLine);
       DownloadFileURL(CurrLine);
      End;
     End;
    End;
   End;
   Close(PacketFile);
    {Supprime le fichier de liste }
   {$I-}Assign(PacketFile,'list.tmp');
   Erase(PacketFile);{$I+}
   If Not(PacketFound)Then Begin
    WriteLn('Aucun paquet avec se nom n''est dans la liste du r‚pertoire');
   End;
  Except
   On E: Exception do
    Writeln('Error: ', E.Message);
  End;
  { LibŠre la m‚moire utilis‚e par l'instance de TFPHTTPClient }
  Client.Free;
 End;
END.