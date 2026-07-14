namespace ABU_BC_Lab.Apps.LuckySheet;

table 70002 "LAB LuckySheet Setup"
{
    Caption = 'LuckySheet Setup';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Show System Fields"; Boolean)
        {
            Caption = 'Show System Fields';
            ToolTip = 'Specifies whether system fields (id 2000000000 and above, such as SystemId and the SystemCreated/Modified fields) are shown in the sheet.';
        }
        field(10; "Show Toolbar"; Boolean)
        {
            Caption = 'Show Toolbar';
            ToolTip = 'Specifies whether the Luckysheet formatting toolbar is shown.';
        }
        field(11; "Show Formula Bar"; Boolean)
        {
            Caption = 'Show Formula Bar';
            ToolTip = 'Specifies whether the Luckysheet cell reference and formula bar is shown.';
        }
        field(12; "Show Sheet Tabs Bar"; Boolean)
        {
            Caption = 'Show Sheet Tabs Bar';
            ToolTip = 'Specifies whether the bottom sheet tabs bar is shown.';
        }
        field(13; "Show Info Bar"; Boolean)
        {
            Caption = 'Show Info Bar';
            ToolTip = 'Specifies whether the top info bar (sheet title and share/save icons) is shown.';
        }
        field(14; "Show Statistic Bar"; Boolean)
        {
            Caption = 'Show Statistic Bar';
            ToolTip = 'Specifies whether the bottom-right statistic and zoom bar is shown.';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetSetup(): Record "LAB LuckySheet Setup"
    begin
        if Get() then
            exit(Rec);

        Init();
        "Show Toolbar" := true;
        "Show Formula Bar" := true;
        "Show Sheet Tabs Bar" := true;
        "Show Info Bar" := false;
        "Show Statistic Bar" := true;
        Insert();
        exit(Rec);
    end;
}
