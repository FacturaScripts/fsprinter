let { ipcRenderer, remote } = require("electron");
let printers = remote.getCurrentWebContents().getPrinters();
console.log(printers);

/// load printer list
printers.map((item, index) => {
    document.getElementById("printer_list").innerHTML +=
      '<option value="' + item.name + '">' + item.name + '</option>';
});

function prinTest() {
  var printerName = document.getElementById("printer_list").value;
  ipcRenderer.send('print-test', printerName);
}

function test2017() {
  alert('test 2017');
}

function test2020() {
  alert('test 2020');
}