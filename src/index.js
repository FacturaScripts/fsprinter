const { ipcRenderer, remote } = require("electron");
const axios = require('axios');
const printers = remote.getCurrentWebContents().getPrinters();
const settings = require('electron-settings');

var printLock = false;

async function connect2017(params) {
  if (false == settings.hasSync('2017.url') || printLock) {
    return;
  }

  printLock = true;
  var url2017 = settings.getSync('2017.url') + '/api.php?v=2&f=remote_printer';
  if (params == '') {
    url2017 += '&terminal=' + settings.getSync('2017.terminal');
  } else {
    url2017 += '&' + params;
  }

  try {
    const response = await fetch(url2017);
    const ticket = await response.text();
    if (response.status == 200 && ticket.trim().length > 0) {
      ipcRenderer.send('print-2017', ticket);
    } else {
      console.log(url2017);
      console.log(response.status);
      console.log(ticket);
      console.log(ticket.trim().length);
    }
  } catch (err) {
    alert('La conexión con fs2017 falló: ' + err);
  }

  printLock = false;
}

async function connect2020(params) {
  if (false == settings.hasSync('2020.url') || printLock) {
    return;
  }

  printLock = true;
  try {
    const apiClient = await axios.create({
      baseURL: settings.getSync('2020.url'),
      headers: {
        Token: settings.getSync('2020.key')
      }
    });
    const response = await apiClient.get('/api/3/ticketes/' + params);
    if (0 < response.data.text.trim().length) {
      ipcRenderer.send('print-2020', response.data);
      apiClient.delete('/api/3/ticketes/' + response.data.coddocument);
    }
  } catch (err) {
    alert('La conexión con fs falló' + err);
  }
  printLock = false;
}

function prinTest() {
  var printerName = document.getElementById("printer_list").value;
  settings.setSync('printer', { name: printerName });
  ipcRenderer.send('print-test', printerName);
}

function test2017() {
  var url2017 = document.getElementById("url_2017").value;
  if (url2017.substring(0, 7) != 'http://' && url2017.substring(0, 8) != 'https://') {
    alert('URL incorrecta');
    return false;
  }

  if (url2017.substring(url2017.length - 8) == '/api.php') {
    url2017 = url2017.substring(0, url2017.length - 8);
  }

  var terminal2017 = document.getElementById("terminal_2017").value ?? '1';
  var timer2017 = document.getElementById("timer_2017").value ?? '10';

  fetch(url2017 + '/api.php?v=2').then(function (response) {
    response.text().then(function (body) {
      if (body != 'Ninguna funcion ejecutada.') {
        alert('No se ha detectado un FacturaScripts 2017 en esta url');
        return false;
      }

      settings.setSync('2017', { url: url2017, terminal: terminal2017, timer: timer2017 });
      alert('Datos guardados correctamente');
      setTimer2017();
    });
    return false;
  });
}

function test2020() {
  var url2020 = document.getElementById("url_2020").value;
  if (url2020.substring(0, 7) != 'http://' && url2020.substring(0, 8) != 'https://') {
    alert('URL incorrecta');
    return false;
  }

  var key2020 = document.getElementById("key_2020").value;
  if (0 == key2020.length) {
    alert('Se necesita una API key');
    return false;
  }

  var cut2020 = document.getElementById("cut_2020").value ?? '';
  var open2020 = document.getElementById("open_2020").value ?? '';
  var timer2020 = document.getElementById("timer_2020").value ?? '10';

  const apiClient = axios.create({
    baseURL: url2020,
    headers: {
      Token: key2020
    }
  });
  apiClient.get('/api/3').then(function (response) {
    // handle success
    settings.setSync('2020', { url: url2020, key: key2020, cut: cut2020, open: open2020, timer: timer2020 });
    alert('Datos guardados correctamente');
    setTimer2020();
  })
    .catch(function (error) {
      // handle error
      console.log(error);
      alert('Error al conectar');
    });
}

// timer 2017 functions
function timer2017() {
  connect2017('');
}

function setTimer2017() {
  if (settings.hasSync('2017.url') &&
    parseInt(document.getElementById("terminal_2017").value) > 0 &&
    parseInt(document.getElementById("timer_2017").value) > 0) {
    var seconds = parseInt(document.getElementById("timer_2017").value);
    var myTimer2017 = setInterval(timer2017, seconds * 1000);
  }
}

// timer 2020 functions
function timer2020() {
  if (false == settings.hasSync('2020.url') || printLock) {
    return;
  }

  printLock = true;
  const apiClient = axios.create({
    baseURL: settings.getSync('2020.url'),
    headers: {
      Token: settings.getSync('2020.key')
    }
  });

  /// get all tickets
  apiClient.get('/api/3/ticketes').then(function (response) {
    response.data.forEach(element => {
      ipcRenderer.send('print-2020', element);

      /// delete
      apiClient.delete('/api/3/ticketes/' + element.coddocument);
    });
  }).catch(function (error) {
    // handle error
    console.log(error);
  });
  printLock = false;
}

function setTimer2020() {
  if (settings.hasSync('2020.url') && parseInt(document.getElementById("timer_2020").value) > 0) {
    var seconds = parseInt(document.getElementById("timer_2020").value);
    var myTimer2020 = setInterval(timer2020, seconds * 1000);
  }
}

// load printer list
var selectedPrinter = settings.getSync('printer.name');
printers.map((item, index) => {
  if (item.name == selectedPrinter) {
    document.getElementById("printer_list").innerHTML +=
      '<option value="' + item.name + '" selected="">' + item.name + '</option>';
  } else {
    document.getElementById("printer_list").innerHTML +=
      '<option value="' + item.name + '">' + item.name + '</option>';
  }
});

// load preferences
if (settings.hasSync('2017.url')) {
  document.getElementById("url_2017").value = settings.getSync('2017.url');
  document.getElementById("terminal_2017").value = settings.getSync('2017.terminal') ?? '1';
  document.getElementById("timer_2017").value = settings.getSync('2017.timer') ?? '10';
  setTimer2017();
} else {
  document.getElementById("terminal_2017").value = '1';
  document.getElementById("timer_2017").value = '10';
}

if (settings.hasSync('2020.url')) {
  document.getElementById("url_2020").value = settings.getSync('2020.url');
  document.getElementById("timer_2020").value = settings.getSync('2020.timer') ?? '10';
  document.getElementById("key_2020").value = settings.getSync('2020.key');
  document.getElementById("cut_2020").value = settings.getSync('2020.cut') ?? '27.105';
  document.getElementById("open_2020").value = settings.getSync('2020.open') ?? '27.112.48';
  setTimer2020();
} else {
  document.getElementById("timer_2020").value = '10';
  document.getElementById("cut_2020").value = '27.105';
  document.getElementById("open_2020").value = '27.112.48';
}

// hand main process message http-request
ipcRenderer.on('http-request-2017', (event, arg) => {
  connect2017(arg)
});
ipcRenderer.on('http-request-2020', (event, arg) => {
  connect2020(arg)
});