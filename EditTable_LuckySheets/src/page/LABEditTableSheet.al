namespace ABU_BC_Lab.Apps.LuckySheet;

using System.Reflection;

page 70000 "LAB Edit Table Sheet"
{
    Caption = 'Edit Table Sheet';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(TableSelection)
            {
                Caption = 'Table Selection';

                field(TableName; SelectedTableName)
                {
                    ApplicationArea = All;
                    Caption = 'Table';
                    ToolTip = 'Specifies the table whose records are loaded into the sheet below.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        AllObjWithCaption: Record AllObjWithCaption;
                    begin
                        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);

                        if PAGE.RunModal(Page::"Objects", AllObjWithCaption) = ACTION::LookupOK then begin
                            SelectedTableName := AllObjWithCaption."Object Name";
                            SelectTable();
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        SelectTable();
                    end;
                }
            }
            group(General)
            {
                ShowCaption = false;
                usercontrol(LuckysheetControl; "LAB Luckysheet")
                {
                    ApplicationArea = All;

                    trigger ControlAddInReady()
                    begin
                        CurrPage.LuckysheetControl.LoadData(this.EditTableSheetMgt.BuildSheetJson(this.SelectedTableId));
                    end;

                    trigger SaveData(jsonData: Text)
                    begin
                        this.EditTableSheetMgt.ApplySheetJson(this.SelectedTableId, jsonData);
                        CurrPage.LuckysheetControl.LoadData(this.EditTableSheetMgt.BuildSheetJson(this.SelectedTableId));
                    end;
                }
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(SaveToBC_Promoted; SaveToBC)
                {
                }
                actionref(LuckySheetTableSetup_Promoted; LuckySheetTableSetup)
                {
                }
            }
        }

        area(Processing)
        {
            action(SaveToBC)
            {
                ApplicationArea = All;
                Caption = 'Save to Table';
                ToolTip = 'Writes the changes made in the sheet back to the selected table. Rows whose primary key does not match an existing record are inserted as new records.';
                Image = Save;

                trigger OnAction()
                begin
                    if SelectedTableId = 0 then
                        Error('Select a table first.');
                    CurrPage.LuckysheetControl.RequestSave();
                end;
            }
            action(LuckySheetTableSetup)
            {
                ApplicationArea = All;
                Caption = 'LuckySheet Table Setup';
                ToolTip = 'Opens the LuckySheet setup for the selected table, or the setup list if no table is selected.';
                Image = Setup;

                trigger OnAction()
                var
                    TableSetup: Record "LAB LuckySheet Table Setup";
                begin
                    if SelectedTableId = 0 then begin
                        PAGE.Run(PAGE::"LAB LuckySheet Tbl. Setup List");
                        exit;
                    end;

                    if not TableSetup.Get(SelectedTableId) then begin
                        TableSetup.Init();
                        TableSetup."Table ID" := SelectedTableId;
                        TableSetup.Insert(true);
                    end;

                    PAGE.Run(PAGE::"LAB LuckySheet Tbl. Setup Card", TableSetup);
                end;
            }
        }
    }


    var
        EditTableSheetMgt: Codeunit "LAB Edit Table Sheet Mgt";
        SelectedTableId: Integer;
        SelectedTableName: Text[250];

    local procedure SelectTable()
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if SelectedTableName = '' then
            SelectedTableId := 0
        else begin
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
            AllObjWithCaption.SetRange("Object Name", SelectedTableName);
            if not AllObjWithCaption.FindFirst() then
                Error('Table %1 was not found.', SelectedTableName);
            SelectedTableId := AllObjWithCaption."Object ID";
        end;

        CurrPage.LuckysheetControl.LoadData(this.EditTableSheetMgt.BuildSheetJson(this.SelectedTableId));
    end;
}
