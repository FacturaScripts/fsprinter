let { ipcRenderer, remote } = require("electron");
let printers = remote.getCurrentWebContents().getPrinters();
let settings = require('electron-settings');

/// load printer list
var selectedPrinter = settings.getSync('printer.name');
printers.map((item, index) => {
  if(item.name == selectedPrinter) {
    document.getElementById("printer_list").innerHTML +=
      '<option value="' + item.name + '" selected="">' + item.name + '</option>';
  } else {
    document.getElementById("printer_list").innerHTML +=
      '<option value="' + item.name + '">' + item.name + '</option>';
  }
});

/// load preferences
document.getElementById("url_2017").value = settings.getSync('2017.url');

function prinTest() {
  var printerName = document.getElementById("printer_list").value;
  settings.setSync('printer', {name: printerName});
  ipcRenderer.send('print-test', printerName);
}

function test2017() {
  var url2017 = document.getElementById("url_2017").value;
  if(url2017.substring(0, 7) != 'http://' && url2017.substring(0, 8) != 'https://') {
    alert('URL incorrecta');
    return false;
  }

  if(url2017.substring(url2017.length - 8) == '/api.php') {
    url2017 = url2017.substring(0, url2017.length - 8);
  }

  fetch(url2017 + '/api.php?v=2').then(function(response) {
    response.text().then(function (body) {
      if(body != 'Ninguna funcion ejecutada.') {
        alert('No se ha detectado un FacturaScripts 2017 en esta url');
        return false;
      }

      alert('oki');
      settings.setSync('2017', {url: url2017});
    });
    return false;
  });
}

function test2020() {
  alert('test 2020');
}