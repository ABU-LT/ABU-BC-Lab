var LSAB_containerId = 'lsabLuckysheetContainer';
var LSAB_headers = [];
var LSAB_originalRows = [];
var LSAB_pendingPayload = null;
var LSAB_assetsLoaded = false;




function InitializeControl(controlId) {
    var controlElement = document.getElementById(controlId);
    if (!controlElement) {
        console.error('Control element not found: ' + controlId);
        return;
    }
    ControlAddInReady(controlElement);
}




function ControlAddInReady(element) {
    element.style.height = '100%';
    element.style.width = '100%';

    var container = document.createElement('div');
    container.id = LSAB_containerId;
    container.style.position = 'absolute';
    container.style.top = '0';
    container.style.bottom = '0';
    container.style.left = '0';
    container.style.right = '0';
    element.appendChild(container);

    LSAB_loadLuckysheetAssets(function () {
        LSAB_assetsLoaded = true;
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlAddInReady', ['default']);
        if (LSAB_pendingPayload) {
            LSAB_renderSheet(LSAB_pendingPayload.headers, LSAB_pendingPayload.rows, LSAB_pendingPayload.sheetName, LSAB_pendingPayload.settings);
            LSAB_pendingPayload = null;
        }
    });
}

function LSAB_loadLuckysheetAssets(onReady) {
    var version = '2.1.13';
    var base = 'https://cdn.jsdelivr.net/npm/luckysheet@' + version + '/dist/';

    [
        base + 'plugins/css/pluginsCss.css',
        base + 'plugins/plugins.css',
        base + 'css/luckysheet.css',
        base + 'assets/iconfont/iconfont.css'
    ].forEach(function (href) {
        var link = document.createElement('link');
        link.rel = 'stylesheet';
        link.href = href;
        document.head.appendChild(link);
    });

    var jsFiles = [base + 'plugins/js/plugin.js', base + 'luckysheet.umd.js'];
    var index = 0;

    function loadNext() {
        if (index >= jsFiles.length) {
            onReady();
            return;
        }
        var script = document.createElement('script');
        script.src = jsFiles[index];
        script.onload = function () {
            index++;
            loadNext();
        };
        document.head.appendChild(script);
    }

    loadNext();
}

function LoadData(jsonData) {
    var payload = JSON.parse(jsonData);
    if (!LSAB_assetsLoaded) {
        LSAB_pendingPayload = payload;
        return;
    }
    LSAB_renderSheet(payload.headers, payload.rows, payload.sheetName, payload.settings);
}

function LSAB_renderSheet(headers, rows, sheetName, settings) {
    LSAB_headers = headers;
    settings = settings || {};

    var headerRow = headers.map(function (h) {
        return { v: h.caption, bl: 1, bg: '#f2f2f2' };
    });

    var sheetData = [headerRow];
    rows.forEach(function (row) {
        sheetData.push(headers.map(function (h) {
            var value = row[h.key];
            return {
                v: value === undefined || value === null ? '' : value,
                ct: { fa: '@', t: 's' }
            };
        }));
    });

    LSAB_originalRows = rows.map(function (row) {
        return headers.map(function (h) {
            var value = row[h.key];
            return value === undefined || value === null ? '' : String(value);
        });
    });

    if (window.luckysheet && typeof luckysheet.destroy === 'function') {
        try { luckysheet.destroy(); } catch (e) { /* not yet created */ }
    }

    luckysheet.create({
        container: LSAB_containerId,
        lang: 'en',
        showtoolbar: settings.showToolbar === true,
        sheetFormulaBar: settings.showFormulaBar === true,
        showsheetbar: settings.showSheetTabsBar === true,
        showinfobar: settings.showInfoBar === true,
        showstatisticBar: settings.showStatisticBar === true,
        data: [{
            name: sheetName || 'Sheet1',
            data: sheetData,
            row: Math.max(sheetData.length + 20, 50),
            column: Math.max(headers.length + 5, 20)
        }]
    });
}

function RequestSave() {
    if (!window.luckysheet) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('SaveData', ['[]']);
        return;
    }

    var sheetData = luckysheet.getluckysheetfile()[0].data;
    var rows = [];

    for (var r = 1; r < sheetData.length; r++) {
        var rowArr = sheetData[r];
        if (!rowArr) {
            continue;
        }
        var isEmpty = rowArr.every(function (cell) {
            return !cell || cell.v === '' || cell.v === undefined || cell.v === null;
        });
        if (isEmpty) {
            continue;
        }

        var currentValues = [];
        for (var c = 0; c < LSAB_headers.length; c++) {
            var cell = rowArr[c];
            currentValues.push((cell && cell.v !== undefined && cell.v !== null) ? String(cell.v) : '');
        }

        var originalValues = LSAB_originalRows[r - 1];
        var isModified = !originalValues || currentValues.some(function (value, index) {
            return value !== originalValues[index];
        });
        if (!isModified) {
            continue;
        }

        var rowObj = {};
        for (var c2 = 0; c2 < LSAB_headers.length; c2++) {
            rowObj[LSAB_headers[c2].key] = currentValues[c2];
        }
        rows.push(rowObj);
    }

    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('SaveData', [JSON.stringify(rows)]);
}
