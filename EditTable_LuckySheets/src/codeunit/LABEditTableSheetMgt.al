namespace ABU_BC_Lab.Apps.LuckySheet;

codeunit 70001 "LAB Edit Table Sheet Mgt"
{
    procedure BuildSheetJson(TableId: Integer): Text
    var
        Setup: Record "LAB LuckySheet Setup";
        RecRef: RecordRef;
        FldRef: FieldRef;
        KeyRef: KeyRef;
        FieldsToCalc: array[1] of FieldRef;
        Headers: JsonArray;
        Rows: JsonArray;
        RowObj: JsonObject;
        Payload: JsonObject;
        Window: Dialog;
        OutText: Text;
        FieldIndex: Integer;
        RowCount: Integer;
        MaxRowCount: Integer;
        TotalRowCount: Integer;
        PrimaryKeyFieldNos: List of [Integer];
        KeyFieldIndex: Integer;
        ProcessingRowsMsg: Label '\Preparing data...\Row:  #1###### of #2######';
    begin
        if TableId = 0 then
            exit('');

        Setup := Setup.GetSetup();

        MaxRowCount := 5000;
        RecRef.Open(TableId);

        TotalRowCount := RecRef.Count();
        if TotalRowCount > MaxRowCount then
            TotalRowCount := MaxRowCount;
        Window.Open(RecRef.Caption + ProcessingRowsMsg);
        Window.Update(2, TotalRowCount);

        KeyRef := RecRef.KeyIndex(1);
        for KeyFieldIndex := 1 to KeyRef.FieldCount do
            PrimaryKeyFieldNos.Add(KeyRef.FieldIndex(KeyFieldIndex).Number);

        for FieldIndex := 1 to RecRef.FieldCount do begin
            FldRef := RecRef.FieldIndex(FieldIndex);
            if IsFieldShown(TableId, FldRef, Setup."Show System Fields") then
                AddHeader(Headers, Format(FldRef.Number), GetHeaderCaption(FldRef, PrimaryKeyFieldNos.Contains(FldRef.Number)));
        end;

        if RecRef.FindSet() then
            repeat
                Clear(RowObj);
                for FieldIndex := 1 to RecRef.FieldCount do begin
                    FldRef := RecRef.FieldIndex(FieldIndex);
                    if IsFieldShown(TableId, FldRef, Setup."Show System Fields") then begin
                        if FldRef.Class = FieldClass::FlowField then begin
                            FldRef.CalcField();
                            FieldsToCalc[1] := FldRef;
                        end;
                        RowObj.Add(Format(FldRef.Number), FormatFieldValue(FldRef));
                    end;
                end;
                Rows.Add(RowObj);
                RowCount += 1;
                if RowCount mod 50 = 0 then
                    Window.Update(1, RowCount);
            until (RecRef.Next() = 0) or (RowCount >= MaxRowCount);

        Window.Close();
        Payload.Add('sheetName', CopyStr(RecRef.Caption, 1, 31));
        RecRef.Close();

        Payload.Add('headers', Headers);
        Payload.Add('rows', Rows);
        Payload.Add('settings', BuildSettingsJson(Setup));
        Payload.WriteTo(OutText);
        exit(OutText);
    end;

    procedure ApplySheetJson(TableId: Integer; JsonData: Text)
    var
        Setup: Record "LAB LuckySheet Setup";
        RecRef: RecordRef;
        FldRef: FieldRef;
        KeyRef: KeyRef;
        RowsArray: JsonArray;
        RowToken: JsonToken;
        RowObj: JsonObject;
        FieldValue: Variant;
        CurrentValue: Variant;
        Window: Dialog;
        ValueText: Text;
        PrimaryKeyFieldNos: List of [Integer];
        RowIndex: Integer;
        FieldIndex: Integer;
        KeyFieldIndex: Integer;
        HasFullKey: Boolean;
        RecordFound: Boolean;
        RecordChanged: Boolean;
        UpdatedCount: Integer;
        InsertedCount: Integer;
        SkippedCount: Integer;
        UnchangedCount: Integer;
        ApplyingRowsMsg: Label 'Applying data...\Row:  #1###### of #2######';
    begin
        if TableId = 0 then
            exit;
        if JsonData = '' then
            exit;
        if not RowsArray.ReadFrom(JsonData) then
            exit;

        Setup := Setup.GetSetup();
        Window.Open(ApplyingRowsMsg);
        Window.Update(2, RowsArray.Count);

        RecRef.Open(TableId);
        KeyRef := RecRef.KeyIndex(1);
        for KeyFieldIndex := 1 to KeyRef.FieldCount do
            PrimaryKeyFieldNos.Add(KeyRef.FieldIndex(KeyFieldIndex).Number);
        RecRef.Close();

        for RowIndex := 0 to RowsArray.Count - 1 do begin
            if RowIndex mod 20 = 0 then
                Window.Update(1, RowIndex + 1);

            RowsArray.Get(RowIndex, RowToken);
            RowObj := RowToken.AsObject();

            RecRef.Open(TableId);
            KeyRef := RecRef.KeyIndex(1);

            HasFullKey := true;
            for KeyFieldIndex := 1 to KeyRef.FieldCount do begin
                FldRef := KeyRef.FieldIndex(KeyFieldIndex);
                if GetJsonValue(RowObj, Format(FldRef.Number), ValueText) and (ValueText <> '') and
                   TryParseFieldValue(FldRef, ValueText, FieldValue)
                then
                    FldRef.SetRange(FieldValue)
                else
                    HasFullKey := false;
            end;

            RecordFound := HasFullKey and RecRef.FindFirst();
            if not RecordFound then
                RecRef.Init();

            RecordChanged := false;
            for FieldIndex := 1 to RecRef.FieldCount do begin
                FldRef := RecRef.FieldIndex(FieldIndex);
                if not (RecordFound and PrimaryKeyFieldNos.Contains(FldRef.Number)) then
                    if IsFieldEditableForSheet(TableId, FldRef, Setup."Show System Fields") and GetJsonValue(RowObj, Format(FldRef.Number), ValueText) then
                        if TryParseFieldValue(FldRef, ValueText, FieldValue) then begin
                            CurrentValue := FldRef.Value;
                            if (not RecordFound) or (Format(CurrentValue) <> Format(FieldValue)) then begin
                                FldRef.Value := FieldValue;
                                if IsFieldValidationEnabled(TableId, FldRef) then
                                    FldRef.Validate();
                                RecordChanged := true;
                            end;
                        end;
            end;

            if RecordFound then begin
                if not RecordChanged then
                    UnchangedCount += 1
                else
                    if RecRef.Modify(IsModifyTriggerEnabled(TableId)) then
                        UpdatedCount += 1
                    else
                        SkippedCount += 1;
            end else
                if RecRef.Insert(IsInsertTriggerEnabled(TableId)) then
                    InsertedCount += 1
                else
                    SkippedCount += 1;

            RecRef.Close();
        end;

        Window.Close();

        if SkippedCount > 0 then
            Message('Updated %1 and inserted %2 record(s). %3 unchanged. %4 row(s) were skipped.', UpdatedCount, InsertedCount, UnchangedCount, SkippedCount)
        else
            Message('Updated %1 and inserted %2 record(s). %3 unchanged.', UpdatedCount, InsertedCount, UnchangedCount);
    end;

    local procedure IsFieldVisible(FldRef: FieldRef; ShowSystemFields: Boolean): Boolean
    begin
        if (FldRef.Number >= 2000000000) and not ShowSystemFields then
            exit(false);
        if not (FldRef.Class in [FieldClass::Normal, FieldClass::FlowField]) then
            exit(false);
        if FldRef.Type in [FieldType::BLOB, FieldType::Media, FieldType::MediaSet, FieldType::TableFilter] then
            exit(false);
        exit(true);
    end;

    local procedure IsFieldEditable(FldRef: FieldRef; ShowSystemFields: Boolean): Boolean
    begin
        if FldRef.Number >= 2000000000 then
            exit(false);
        exit(IsFieldVisible(FldRef, ShowSystemFields) and (FldRef.Class = FieldClass::Normal));
    end;

    local procedure IsFieldShown(TableId: Integer; FldRef: FieldRef; ShowSystemFields: Boolean): Boolean
    var
        FieldSetup: Record "LAB LuckySheet Field Setup";
    begin
        if not IsFieldVisible(FldRef, ShowSystemFields) then
            exit(false);
        if FieldSetup.Get(TableId, FldRef.Number) then
            exit(FieldSetup."Show in LuckySheet");
        exit(true);
    end;

    local procedure IsFieldEditableForSheet(TableId: Integer; FldRef: FieldRef; ShowSystemFields: Boolean): Boolean
    var
        FieldSetup: Record "LAB LuckySheet Field Setup";
    begin
        if not IsFieldEditable(FldRef, ShowSystemFields) then
            exit(false);
        if FieldSetup.Get(TableId, FldRef.Number) then
            exit(FieldSetup."Show in LuckySheet");
        exit(true);
    end;

    local procedure IsFieldValidationEnabled(TableId: Integer; FldRef: FieldRef): Boolean
    var
        FieldSetup: Record "LAB LuckySheet Field Setup";
    begin
        if FieldSetup.Get(TableId, FldRef.Number) then
            exit(FieldSetup."Activate Field Validation");
        exit(true);
    end;

    local procedure IsModifyTriggerEnabled(TableId: Integer): Boolean
    var
        TableSetup: Record "LAB LuckySheet Table Setup";
    begin
        if TableSetup.Get(TableId) then
            exit(TableSetup."Activate Modify Trigger");
        exit(true);
    end;

    local procedure IsInsertTriggerEnabled(TableId: Integer): Boolean
    var
        TableSetup: Record "LAB LuckySheet Table Setup";
    begin
        if TableSetup.Get(TableId) then
            exit(TableSetup."Activate Insert Trigger");
        exit(true);
    end;

    local procedure BuildSettingsJson(Setup: Record "LAB LuckySheet Setup"): JsonObject
    var
        SettingsObj: JsonObject;
    begin
        SettingsObj.Add('showToolbar', Setup."Show Toolbar");
        SettingsObj.Add('showFormulaBar', Setup."Show Formula Bar");
        SettingsObj.Add('showSheetTabsBar', Setup."Show Sheet Tabs Bar");
        SettingsObj.Add('showInfoBar', Setup."Show Info Bar");
        SettingsObj.Add('showStatisticBar', Setup."Show Statistic Bar");
        exit(SettingsObj);
    end;

    local procedure GetHeaderCaption(FldRef: FieldRef; IsPrimaryKeyField: Boolean): Text
    var
        CaptionText: Text;
    begin
        CaptionText := StrSubstNo('(%1) %2', FldRef.Number, FldRef.Caption);
        if FldRef.Class = FieldClass::FlowField then
            CaptionText += ' [Calculated]';
        if IsPrimaryKeyField then
            CaptionText := '(PK) ' + CaptionText;
        exit(CaptionText);
    end;

    local procedure FormatFieldValue(FldRef: FieldRef): Text
    var
        DateVal: Date;
        DateTimeVal: DateTime;
        OptionOrdinal: Integer;
    begin
        case FldRef.Type of
            FieldType::Date:
                begin
                    DateVal := FldRef.Value;
                    if DateVal = 0D then
                        exit('');
                    exit(Format(DateVal, 0, 9));
                end;
            FieldType::DateTime:
                begin
                    DateTimeVal := FldRef.Value;
                    if DateTimeVal = 0DT then
                        exit('');
                    exit(Format(DateTimeVal, 0, 9));
                end;
            FieldType::Option:
                begin
                    OptionOrdinal := FldRef.Value;
                    exit(GetOptionCaptionByOrdinal(FldRef, OptionOrdinal));
                end;
            else
                exit(Format(FldRef.Value));
        end;
    end;

    local procedure GetOptionCaptionByOrdinal(FldRef: FieldRef; OptionOrdinal: Integer): Text
    var
        Captions: List of [Text];
    begin
        Captions := FldRef.OptionCaption.Split(',');
        if (OptionOrdinal >= 0) and (OptionOrdinal < Captions.Count) then
            exit(Captions.Get(OptionOrdinal + 1).Trim());
        exit('');
    end;

    local procedure TryParseFieldValue(FldRef: FieldRef; ValueText: Text; var ValueVariant: Variant): Boolean
    var
        IntVal: Integer;
        BigIntVal: BigInteger;
        DecVal: Decimal;
        DateVal: Date;
        DateTimeVal: DateTime;
        TimeVal: Time;
        BoolVal: Boolean;
        GuidVal: Guid;
        DurationVal: Duration;
        OptionOrdinal: Integer;
    begin
        case FldRef.Type of
            FieldType::Text, FieldType::Code:
                begin
                    ValueVariant := CopyStr(ValueText, 1, FldRef.Length);
                    exit(true);
                end;
            FieldType::Integer:
                begin
                    if ValueText = '' then
                        ValueVariant := 0
                    else
                        if not Evaluate(IntVal, ValueText) then
                            exit(false)
                        else
                            ValueVariant := IntVal;
                    exit(true);
                end;
            FieldType::BigInteger:
                begin
                    if ValueText = '' then
                        ValueVariant := 0
                    else
                        if not Evaluate(BigIntVal, ValueText) then
                            exit(false)
                        else
                            ValueVariant := BigIntVal;
                    exit(true);
                end;
            FieldType::Decimal:
                begin
                    if ValueText = '' then
                        ValueVariant := 0
                    else
                        if not Evaluate(DecVal, ValueText) then
                            exit(false)
                        else
                            ValueVariant := DecVal;
                    exit(true);
                end;
            FieldType::Boolean:
                begin
                    if ValueText = '' then
                        ValueVariant := false
                    else
                        if not Evaluate(BoolVal, ValueText) then
                            exit(false)
                        else
                            ValueVariant := BoolVal;
                    exit(true);
                end;
            FieldType::Date:
                begin
                    if ValueText = '' then
                        ValueVariant := 0D
                    else
                        if not Evaluate(DateVal, ValueText, 9) then
                            exit(false)
                        else
                            ValueVariant := DateVal;
                    exit(true);
                end;
            FieldType::DateTime:
                begin
                    if ValueText = '' then
                        ValueVariant := 0DT
                    else
                        if not Evaluate(DateTimeVal, ValueText, 9) then
                            exit(false)
                        else
                            ValueVariant := DateTimeVal;
                    exit(true);
                end;
            FieldType::Time:
                begin
                    if ValueText = '' then
                        ValueVariant := 0T
                    else
                        if not Evaluate(TimeVal, ValueText, 9) then
                            exit(false)
                        else
                            ValueVariant := TimeVal;
                    exit(true);
                end;
            FieldType::Duration:
                begin
                    if ValueText = '' then
                        ValueVariant := 0
                    else
                        if not Evaluate(DurationVal, ValueText) then
                            exit(false)
                        else
                            ValueVariant := DurationVal;
                    exit(true);
                end;
            FieldType::Guid:
                begin
                    if ValueText = '' then
                        exit(false);
                    if not Evaluate(GuidVal, ValueText) then
                        exit(false);
                    ValueVariant := GuidVal;
                    exit(true);
                end;
            FieldType::Option:
                begin
                    if not TryGetOptionOrdinal(FldRef, ValueText, OptionOrdinal) then
                        exit(false);
                    ValueVariant := OptionOrdinal;
                    exit(true);
                end;
            else
                exit(false);
        end;
    end;

    local procedure TryGetOptionOrdinal(FldRef: FieldRef; ValueText: Text; var OptionOrdinal: Integer): Boolean
    var
        Captions: List of [Text];
        CaptionIndex: Integer;
    begin
        Captions := FldRef.OptionCaption.Split(',');
        for CaptionIndex := 1 to Captions.Count do
            if Captions.Get(CaptionIndex).Trim() = ValueText then begin
                OptionOrdinal := CaptionIndex - 1;
                exit(true);
            end;
        exit(false);
    end;

    local procedure AddHeader(var Headers: JsonArray; HeaderKey: Text; HeaderCaption: Text)
    var
        HeaderObj: JsonObject;
    begin
        HeaderObj.Add('key', HeaderKey);
        HeaderObj.Add('caption', HeaderCaption);
        Headers.Add(HeaderObj);
    end;

    local procedure GetJsonValue(RowObj: JsonObject; FieldKey: Text; var ValueText: Text): Boolean
    var
        FieldToken: JsonToken;
    begin
        if not RowObj.Get(FieldKey, FieldToken) then
            exit(false);
        if FieldToken.AsValue().IsNull then
            exit(false);
        ValueText := FieldToken.AsValue().AsText();
        exit(true);
    end;
}
