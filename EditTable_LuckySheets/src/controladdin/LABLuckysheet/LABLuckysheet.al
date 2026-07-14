namespace ABU_BC_Lab.Apps.LuckySheet;

controladdin "LAB Luckysheet"
{
    Scripts = 'src/controladdin/LABLuckysheet/Source/plugin.js', 'src/controladdin/LABLuckysheet/Source/luckysheet.umd.js', 'src/controladdin/LABLuckysheet/script.js';
    StartupScript = 'src/controladdin/LABLuckysheet/startup.js';
    StyleSheets = 'src/controladdin/LABLuckysheet/Source/pluginsCss.css', 'src/controladdin/LABLuckysheet/Source/plugins.css', 'src/controladdin/LABLuckysheet/Source/luckysheet.css', 'src/controladdin/LABLuckysheet/Source/iconfont.css';
    HorizontalStretch = true;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalShrink = true;
    RequestedHeight = 600;
    RequestedWidth = 900;

    event ControlAddInReady();
    event SaveData(jsonData: Text);

    procedure LoadData(jsonData: Text);
    procedure RequestSave();
}