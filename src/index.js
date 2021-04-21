const { ipcRenderer, remote } = require("electron");
const axios = require('axios');
const printers = remote.getCurrentWebContents().getPrinters();
const settings = require('electron-settings');

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
if(settings.hasSync('2017.url')) {
  document.getElementById("url_2017").value = settings.getSync('2017.url');
}
if(settings.hasSync('2020.url')) {
  document.getElementById("url_2020").value = settings.getSync('2020.url');
  document.getElementById("key_2020").value = settings.getSync('2020.key');
  document.getElementById("cut_code_2020").value = settings.getSync('2020.cut') ?? '27.105';
  document.getElementById("open_code_2020").value = settings.getSync('2020.open') ?? '27.112.48';
}

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

      alert('Datos guardados correctamente');
      settings.setSync('2017', {url: url2017});
    });
    return false;
  });
}

function test2020() {
  var cutCode = document.getElementById("cut_code_2020").value ?? '';
  var openCode = document.getElementById("open_code_2020").value ?? '';

  var url2020 = document.getElementById("url_2020").value;
  if(url2020.substring(0, 7) != 'http://' && url2020.substring(0, 8) != 'https://') {
    alert('URL incorrecta');
    return false;
  }

  var key2020 = document.getElementById("key_2020").value;
  if(0 == key2020.length) {
    alert('Se necesita una API key');
    return false;
  }

  const apiClient = axios.create({
    baseURL: url2020,
    headers: {
      Token: key2020
    }
  });
  apiClient.get('/api/3').then(function (response) {
    // handle success
    console.log(response);
    alert('Datos guardados correctamente');
    settings.setSync('2020', {url: url2020, key: key2020, cut: cutCode, open: openCode});
  })
  .catch(function (error) {
    // handle error
    console.log(error);
    alert('Error al conectar');
  });
}