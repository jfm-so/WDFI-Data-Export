procedure ProcessFile;
var
  datafl, l: String;
  F: TextFile;
  t, c, e: Integer;
  dl: Short;
  unicon1: TUniConnection;
  uniqry1: TUniQuery;
  pCORP_NAME, pCORP_NO, pCORP_TYPE, pCT_STS, pREG_AGENT: String;
  pADDR_LINE1, pADDR_CITY, pADDR_STATE, pADDR_ZIP: String;
  pDATE_INCORP, pCT_DATE: TDateTime;
  fs: TFormatSettings;
  d: String;
begin
  fs := TFormatSettings.Create('en-US');
  fs.ShortDateFormat := 'MM/DD/YYYY';

  datafl := ExtractFilePath(ParamStr(0)) + 'data.txt';
  AssignFile(F, datafl);
  Reset(F);
  t := 0;
  while not EOF(F) do
  begin
    Readln(F, l);
    Inc(t);
  end;
  CloseFile(F);

  unicon1 := TUniConnection.Create(Nil);
  uniqry1 := TUniQuery.Create(unicon1);
  try
    unicon1.ProviderName := 'MySQL';
    unicon1.Server := 'localhost';
    unicon1.Database := 'wdfi_database';
    unicon1.Username := 'root';
    unicon1.Password := 'root';

    unicon1.Connected := True;

    uniqry1.Connection := unicon1;
    uniqry1.SQL.Text := 'INSERT INTO corpn_data ( id, corp_name, corp_no, corp_type, ' +
      ' date_incorp, ct_sts, ct_date, reg_agent, addr_line1, addr_city,' +
      ' addr_state, addr_zip ) VALUES ( :ID, :CORP_NAME, :CORP_NO, ' +
      ' :CORP_TYPE, :DATE_INCORP, :CT_STS, :CT_DATE, :REG_AGENT,  :ADDR_LINE1, :ADDR_CITY, ' +
      ' :ADDR_STATE, :ADDR_ZIP )';

    AssignFile(F, datafl);
    Reset(F);
    c := 0;
    e := 0;
    unicon1.StartTransaction;
    while not EOF(F) do
    begin
      pCORP_NAME := EmptyStr;
      pCORP_NO := EmptyStr;
      pCORP_TYPE := EmptyStr;
      pDATE_INCORP := Date;
      pCT_STS := EmptyStr;
      pCT_DATE := Date;
      pREG_AGENT := EmptyStr;
      pADDR_LINE1 := EmptyStr;
      pADDR_CITY := EmptyStr;
      pADDR_STATE := EmptyStr;
      pADDR_ZIP := EmptyStr;

      Readln(F, l);

      if (l = EmptyStr) or (Copy(l, 1, 4) = 'DATE') or (Copy(l, 1, 5) = #12'DATE') or
        (Copy(l, 1, 16) = 'CORPORATION NAME') or (Copy(l, 2, 16) = 'REGISTERED AGENT') then
      begin
        Inc(c);
        Continue;
      end;

      for dl := 1 to 3 do
      begin
        case dl of
          1:
            begin
              pCORP_NAME := Copy(l, 1, 68);
              pCORP_TYPE := Copy(l, 70, 2);
              d := Copy(l, 105, 10);
              TryStrToDate(d, pDATE_INCORP, fs);
              pCT_STS := Copy(l, 119, 3);
              d := Copy(l, 123, 10);
              TryStrToDate(d, pCT_DATE, fs);
            end;
          2:
            begin
              pREG_AGENT := Copy(l, 2, 36);
              pADDR_LINE1 := Copy(l, 40, 32);
              pADDR_CITY := Copy(l, 73, 30);
              pADDR_STATE := Copy(l, 105, 2);
              pADDR_ZIP := Copy(l, 108, 10);
            end;
          3:
            begin

            end;
        end;

        Readln(F, l);
        Inc(c);
      end;

      uniqry1.Prepare;
      uniqry1.ParamByName('CORP_NAME').AsString := Trim(pCORP_NAME);
      uniqry1.ParamByName('CORP_NO').AsString := Trim(pCORP_NO);
      uniqry1.ParamByName('CORP_TYPE').AsString := Trim(pCORP_TYPE);
      uniqry1.ParamByName('DATE_INCORP').AsDate := pDATE_INCORP;
      uniqry1.ParamByName('CT_STS').AsString := Trim(pCT_STS);
      uniqry1.ParamByName('CT_DATE').AsDate := pCT_DATE;
      uniqry1.ParamByName('REG_AGENT').AsString := Trim(pREG_AGENT);
      uniqry1.ParamByName('ADDR_LINE1').AsString := Trim(pADDR_LINE1);
      uniqry1.ParamByName('ADDR_CITY').AsString := Trim(pADDR_CITY);
      uniqry1.ParamByName('ADDR_STATE').AsString := Trim(pADDR_STATE);
      uniqry1.ParamByName('ADDR_ZIP').AsString := Trim(pADDR_ZIP);

      try
        uniqry1.Execute;
      except
        Inc(e);
        Inc(c);

        Continue;
      end;

      Inc(c);
      if (c mod 1000 = 0) then
      begin
        if (unicon1.InTransaction) then
          unicon1.Commit;
        unicon1.StartTransaction;
      end;

    end;
    CloseFile(F);
    if (unicon1.InTransaction) then
      unicon1.Commit;

    unicon1.Connected := False;
  finally
    uniqry1.Free;
    unicon1.Free;
  end;


end;
