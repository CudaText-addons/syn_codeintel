{$I-}
library SynJedi;

uses
  Windows,
  SysUtils,
  IniFiles,
  ATSynPlugins,
  ATxSomeProc,
  ATxTcp;

var
  _ActionProc: TSynAction;
  opDataDir: string; //folder with "python3" and "server.py"
  opDllName: string; //dll filename without extension
  opEnableHints: boolean = true; //enable "Parameter hints" feature
  opPortNum: integer = 11112; //server port number
  opHintDelay: integer = 1800; //delay, msec, after error message in editor statusbar
  opHideServer: boolean = false;
  opStartDelay: integer = 1500;

const
  cShowMode: array[boolean] of Integer = (SW_MINIMIZE, SW_HIDE); //server window show mode
  cStrError = '[error]'#10;
  cStrResult = '[result]'#10;

procedure Msg(const S: Widestring; APause: boolean = true);
begin
  _ActionProc(nil, cActionShowHint, PWChar('['+opDllName+'] '+S), nil, nil, nil);
  if APause then
    Sleep(opHintDelay);
end;

procedure SynInit(ADefaultIni: PWideChar; AActionProc: Pointer); stdcall;
var
  fn, AExeDir, AIniFN: string;
begin
  _ActionProc:= AActionProc;
  //_DefaultIni:= Widestring(PWChar(ADefaultIni));

  fn:= GetModuleName(HInstance);
  opDllName:= ChangeFileExt(ExtractFileName(fn), '');
  AExeDir:= ExtractFileDir(fn);
  AIniFN:= ChangeFileExt(fn, '.ini');

  opDataDir:= SReadIniKey('ini', 'datadir', AExeDir, AIniFN);
  opEnableHints:= SReadIniKey('ini', 'hints', '1', AIniFN) = '1';
  opHideServer:= SReadIniKey('ini', 'server_hide', '0', AIniFN) = '1';
  //opCloseServer:= SReadIniKey('ini', 'server_close', '0', AIniFN) = '1';
  opPortNum:= StrToInt(SReadIniKey('ini', 'server_port', IntToStr(opPortNum), AIniFN));
end;


function SGetFileProp(
  var fn_editor, fn_src: string;
  var caret_line, caret_col: integer;
  var AMsg: string;
  ATruncLine: boolean): boolean;
const
  cMaxLineSize = 255;
var
  buf: array[0..Pred(cMaxLineSize)] of Widechar;
  Str: Widestring;
  NLine, NCol, NOffset, NSize, i: Integer;
  F: TextFile;
begin
  Result:= false;
  fn_editor:= '';
  fn_src:= '';
  caret_line:= 1;
  caret_col:= 1;
  AMsg:= '';
  Str:= '';

  //get filename
  FillChar(buf, SizeOf(buf), 0);
  if _ActionProc(nil, cActionGetOpenedFileName, PWChar(@buf), Pointer(cSynIdCurrentFile), nil, nil)<>cSynOK then Exit;
  fn_editor:= buf;
  if fn_editor='' then
  begin
    AMsg:= 'Cannot handle unnamed file tab';
    Exit
  end;

  fn_src:= ChangeFileExt(fn_editor, '_tempSyn' + ExtractFileExt(fn_editor));
  AssignFile(F, fn_src);
  try
    Rewrite(F);
    if IOResult<>0 then
    begin
      AMsg:= 'Cannot create temp file (in source code folder)';
      Exit
    end;

    //get caret pos
    if _ActionProc(nil, cActionGetCaretPos, Pointer(@NCol), Pointer(@NLine), Pointer(@NOffset), nil)<>cSynOK then
    begin
      AMsg:= 'Cannot get caret pos';
      Exit;
    end;
    caret_line:= NLine+1;
    caret_col:= NCol+1;  

    //get all lines before current line
    for i:= 0 to NLine-1 do
    begin
      NSize:= SizeOf(buf) div 2;
      if _ActionProc(nil, cActionGetText, Pointer(i), Pointer(@buf), Pointer(@NSize), nil)<>cSynOK then Break;
      Str:= buf;
      Writeln(F, Str);
    end;

    //get current line (truncated by caret pos)
    NSize:= SizeOf(buf) div 2;
    if _ActionProc(nil, cActionGetText, Pointer(NLine), Pointer(@buf), Pointer(@NSize), nil)<>cSynOK then
    begin
      AMsg:= 'Cannot get editor text';
      Exit
    end;  
    Str:= buf;

    if ATruncLine then
    begin
      //cut line after caret
      Delete(Str, NCol+1, MaxInt);

      //cut last id from line (it confuses CodeIntel)
      i:= Length(Str);
      while (i>0) and IsWordChar(Str[i]) do Dec(i);
      Delete(Str, i+1, MaxInt);
      caret_col:= i+1;
    end;  

    Write(F, Str); //not Writeln
    Result:= true;
  finally
    CloseFile(F);
  end;
end;

function IsServerRun: boolean;
begin
  Result:= true;
  try
    UrlRequest('?action=', '?action=noclose', opPortNum);
  except
    Result:= false;
  end;
end;

procedure DoServerClose;
begin
  try
    UrlRequest('?action=close', '?action=noclose', opPortNum);
  except
  end;
end;

function DoServerRun: boolean;
const
  cShowMode: array[boolean] of Integer = (SW_MINIMIZE, SW_HIDE);
var
  sServerDir, sCmd, sParams: string;
begin
  sServerDir:= opDataDir + '\server';
  with TIniFile.Create(sServerDir + '\server.ini') do
  try
    sCmd:= ReadString('ini', 'cmd', '');
    sParams:= ReadString('ini', 'params', '');
  finally
    Free
  end;

  if sCmd='' then
  begin
    Msg('Cannot read params from server.ini');
    Result:= false;
    Exit
  end;

  SReplaceAll(sCmd, '{dir}', sServerDir);
  SReplaceAll(sParams, '{dir}', sServerDir);
  SReplaceAll(sParams, '{port}', IntToStr(opPortNum));
  //ShowMessage(sCmd+#13+sParams);////

  Result:= FExecCmd(sCmd, sParams, sServerDir, cShowMode[opHideServer]);
  if Result then
    Sleep(opStartDelay);
end;


function SynAction(AHandle: Pointer; AName: PWideChar; A1, A2, A3, A4: Pointer): Integer; stdcall;
var
  SAction: Widestring;
  AResultText: Widestring;
  fn_editor, fn_src: string;
  S, AErrorMsg, AActionId: string;
  res_fn: string;
  num_line, num_col: integer;
  res_line, res_col: integer;
  i: integer;
begin
  Result:= cSynError;
  SAction:= PWideChar(AName);

  if not IsServerRun then
  begin
    if not DoServerRun then
    begin
      Msg('Cannot run server');
      Result:= cSynError;
      Exit
    end;
    //wait for server reply
    for i:= 1 to 20 do
    begin
      Sleep(250);
      if IsServerRun then Break;
    end;
  end;

  //auto-completion
  if (SAction=cActionGetAutoComplete) or
    (SAction=cActionFindID) or
    (opEnableHints and (SAction=cActionGetFunctionHint)) then
  begin
    if SAction=cActionGetAutoComplete then
      AActionId:= 'autocomp'
    else
    if SAction=cActionGetFunctionHint then
      AActionId:= 'funchint'
    else
    if SAction=cActionFindID then
      AActionId:= 'findid'
    else
      AActionId:= '';

    if not SGetFileProp(fn_editor, fn_src, num_line, num_col, AErrorMsg, SAction<>cActionFindID) then
    begin
      if AErrorMsg<>'' then
        Msg(AErrorMsg)
      else
        Msg('Cannot get editor properties');
      Exit
    end;

    try
      try
        s:= UrlRequest(
          Format('?action=%s&fn=%s&line=%d&column=%d',
            [AActionId, UrlEncode(fn_src), num_line, num_col]),
          '?action=noclose',
          opPortNum);
      finally
        DeleteFile(fn_src);
      end;  
    except
      Msg('Cannot connect to server');
      Result:= cSynError;
      Exit;
    end;

    if SDeleteBegin(s, cStrResult) then
      begin end
    else
    if SDeleteBegin(s, cStrError) then
      begin Msg(s); Result:= cSynError; Exit end
    else
      begin Msg(s); Result:= cSynError; Exit end;

    //results for find-id
    if SAction=cActionFindID then
    begin
      res_fn:= SGetItem(s, #10);
      res_line:= StrToIntDef(SGetItem(S, #10), 1);
      res_col:= StrToIntDef(SGetItem(S, #10), 0)+1;

      //we can get result in our temp file-> redirect to editor file
      if UpperCase(res_fn) = UpperCase(fn_src) then
        res_fn:= fn_editor;

      //we found filename, open the editor now
      if (res_fn='') or not FileExists(res_fn) then
      begin
        Msg('Cannot find file: '+res_fn);
        Exit
      end;

      if _ActionProc(nil, cActionOpenFile, PWChar(Widestring(res_fn)), nil, nil, nil)<>cSynOK then
      begin
        Msg('Cannot open file: '+res_fn);
        Exit
      end;

      if _ActionProc(nil, cActionSetCaretPos, Pointer(res_col-1), Pointer(res_line-1), nil, nil)<>cSynOK then
      begin
        Msg('Cannot position caret');
        Exit
      end;

      Msg(Format('Found: %s : %d', [ExtractFileName(res_fn), res_line]), false);
      Result:= cSynOK;
    end
    else
    //results for auto-complete and func-hint
    begin
      AResultText:= s;
      lstrcpynw(A1, PWChar(AResultText), Integer(A2));
      Result:= cSynOK;
    end;
    Exit
  end;

  Result:= cSynBadCmd;
end;

exports
  SynAction,
  SynInit;

//following is to check types
var
  _Action: TSynAction;
  _Init: TSynInit;
begin
  _Action:= SynAction;
  _Init:= SynInit;
  if @_Action<>nil then begin end;
  if @_Init<>nil then begin end;

end.
