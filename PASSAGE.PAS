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
 PacketName:String;
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

Function SplitFileName(s:String):String;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(S,D,N,E);
 Splitfilename:=N+E;
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
    Writeln('Error: ', E.Message);
  End;
 Client.Free;
 {$I-}Assign(FileDownload,FileName);
 Rewrite(FileDownload);{$I+}
 If IOResult<>0 Then Begin
  WriteLn('Impossible d''Çcrire le fichier : ',FileName);
  Halt(1);
 End;
 Writeln(FileDownload,Response);
 Close(FileDownload);
End;

BEGIN
 If(ParamStr(1)='/?')or(ParamStr(1)='--help')or(ParamStr(1)='-h')or
   (ParamStr(1)='/h')or(ParamStr(1)='/H')Then Begin
  WriteLn('PASSAGE : Cette commande permet de lancer le gestionnaire de ');
  WriteLn('       paquet Pascal (PasSage).');
  WriteLn;
  WriteLn('Syntaxe : PASSAGE nomdupaquet');
  WriteLn;
  WriteLn(' nomdupaquet Ce paramätre permet d''indiquer le nom du paquet Ö tÇlÇcharger.');
  WriteLn(' --help     Ce paramätre permet de retourner de l''aide sur cette commande');
  WriteLn(' --version  Ce paramätre permet de retourner la version de la commande');
 End
  Else
 If ParamStr(1)='--version'Then Begin
  WriteLn('PASSAGE 0.1 - PasSage de passage ou corail');
  WriteLn('Licence MIT');
  WriteLn;
  WriteLn('êcrit par Sylvain Maltais');
 End
  Else
 Begin
  URL:='https://raw.githubusercontent.com/gladir/passage/refs/heads/main/LIST/list.001';
  PacketName:=ParamStr(1);
  If PacketName=''Then Begin
   WriteLn('Un nom de paquet est requis comme paramätre !');
   Halt(1);
  End;
   { CrÇe une instance de TFPHTTPClient }
  Client:=TFPHTTPClient.Create(nil);
  Try
    {CrÇe le fichier de liste }
   Response:=Client.SimpleGet(URL);
   {$I-}Assign(PacketFile,'list.tmp');
   Rewrite(PacketFile);{$I+}
   If IOResult<>0 Then Begin
    WriteLn('Impossible d''Çcrire les donnÇes temporaires');
    Halt(1);
   End;
   Writeln(PacketFile,Response);
   Close(PacketFile);
    {Lit le fichier de liste }
   {$I-}Assign(PacketFile,'list.tmp');
   Reset(PacketFile);{$I+}
   If IOResult<>0 Then Begin
    WriteLn('Impossible de lire les donnÇes temporaires');
    Halt(1);
   End;
   InPacket:=False;
   PacketFound:=False;
   While Not EOF(PacketFile)do Begin
    ReadLn(PacketFile,CurrLine);
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
      ExecuteProcess(Copy(CurrLine,Length('MAKE:')+2,255),'');
     End
      Else
     Begin
      DownloadFileURL(CurrLine);
     End;
    End;
   End;
   Close(PacketFile);
    {Supprime le fichier de liste }
   {$I-}Assign(PacketFile,'list.tmp');
   Erase(PacketFile);{$I+}
   If Not(PacketFound)Then Begin
    WriteLn('Aucun paquet avec se nom n''est dans la liste du rÇpertoire');
   End;
  Except
   On E: Exception do
    Writeln('Error: ', E.Message);
  End;
  { Libäre la mÇmoire utilisÇe par l'instance de TFPHTTPClient }
  Client.Free;
 End;
END.