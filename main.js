const { app, BrowserWindow, dialog, ipcMain } = require('electron');
const { exec } = require('child_process');
const axios = require('axios');
const fetch = require("node-fetch");
const fs = require('fs');
const os = require('os');
const settings = require('electron-settings');

function connect2017(params) {
  console.log('2017 request')
  if(settings.hasSync('2017.url')) {
    var url2017 = settings.getSync('2017.url');
    fetch(url2017 + '/api.php?v=2&f=remote_printer&' + params).then(function(response) {
      response.text().then(function (body) {
        if(0 == body.trim().length) {
          return;
        }

        /// save body response to file
        fs.writeFile("pos.txt", body, function(err) {
          if(err) {
            return console.log(err);
          }

          prinTicket(settings.getSync('printer.name'));
        });
      });
    });
  }
}

function connect2020(params) {
  console.log('2020 request')
  if(settings.hasSync('2020.url')) {
    const apiClient = axios.create({
      baseURL: settings.getSync('2020.url'),
      headers: {
        Token: settings.getSync('2020.key')
      }
    });
    apiClient.get('/api/3/ticketes/' + params).then(function (response) {
      var ticket = response.data.text;

      /// apply cut command
      var cutCode = settings.getSync('2020.cut') ?? '27.105';
      var cutComm = cutCode.split('.');
      if (cutComm.length > 0 && response.data.cortarpapel) {
        ticket += String.fromCharCode(...cutComm);
      }

      /// apply open command
      var openCode = settings.getSync('2020.open') ?? '27.112.48';
      var openComm = openCode.split('.');
      if (openComm.length > 0 && response.data.abrircajon) {
        ticket += String.fromCharCode(...openComm);
      }

      fs.writeFile("pos.txt", ticket, function(err) {
        if(err) {
          return console.log(err);
        }

        prinTicket(settings.getSync('printer.name'));
      });
    })
    .catch(function (error) {
      // handle error
      console.log(error);
    });
  }
}

function createWindow () {
  const win = new BrowserWindow({
    width: 600,
    height: 620,
    webPreferences: {
      contextIsolation: false,
      enableRemoteModule: true,
      nodeIntegration: true
    }
  })
  
  win.removeMenu();
  //win.webContents.openDevTools();
  win.loadFile('src/index.html');
}

function prinTesTicket(printerName) {
  var esc = '\x1B'; //ESC byte in hex notation
  var newLine = '\x0A'; //LF byte in hex notation
  var cmds = esc + "@"; //Initializes the printer (ESC @)
  cmds += esc + '!' + '\x38'; //Emphasized + Double-height + Double-width mode selected (ESC ! (8 + 16 + 32)) 56 dec => 38 hex
  cmds += 'PRUEBA'; //text to print
  cmds += newLine + newLine;
  cmds += esc + '!' + '\x00'; //Character font A selected (ESC ! 0)
  cmds += 'COOKIES                   5.00'; 
  cmds += newLine;
  cmds += 'MILK 65 Fl oz             3.78';
  cmds += newLine + newLine;
  cmds += 'SUBTOTAL                  8.78';
  cmds += newLine;
  cmds += 'TAX 5%                    0.44';
  cmds += newLine;
  cmds += 'TOTAL                     9.22';
  cmds += newLine;
  cmds += 'CASH TEND                10.00';
  cmds += newLine;
  cmds += 'CASH DUE                  0.78';
  cmds += newLine + newLine + newLine + newLine;

  fs.writeFile("pos.txt", cmds, function(err) {
    if(err) {
      return console.log(err);
    }

    prinTicket(printerName);
  });
}

function prinTicket(printerName) {
  var printCmd = "lp -d " + printerName + " pos.txt";
  if(os.platform() == 'win32') {
    var fullPath = '"' + app.getAppPath() + "\\";
    printCmd = fullPath + 'RawPrint.exe" "' + printerName + '" pos.txt';
  }

  exec(printCmd, (error, stdout, stderr) => {
    if (error) {
      console.log(`error: ${error.message}`);
      dialog.showErrorBox("print error", error.message);
      return;
    }
    if (stderr) {
      console.log(`stderr: ${stderr}`);
      return;
    }
  });
}

app.whenReady().then(createWindow)

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
})

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
})

ipcMain.on('print-test', (event, arg) => {
  prinTesTicket(arg);
  event.reply('print-test', 'ok');
})

ipcMain.on('timer-2017', (event, arg) => {
  var url2017 = settings.getSync('2017.url');
    fetch(url2017 + '/api.php?v=2&f=remote_printer&terminal=' + settings.getSync('2017.terminal')).then(function(response) {
      response.text().then(function (body) {
        if(0 == body.trim().length) {
          return;
        }

        /// save body response to file
        fs.writeFile("pos.txt", body, function(err) {
          if(err) {
            return console.log(err);
          }

          prinTicket(settings.getSync('printer.name'));
        });
      });
    });
  event.reply('timer-2017', 'ok');
})

ipcMain.on('timer-2020', (event, arg) => {
  if(settings.hasSync('2020.url')) {
    const apiClient = axios.create({
      baseURL: settings.getSync('2020.url'),
      headers: {
        Token: settings.getSync('2020.key')
      }
    });
    /// get all tickets
    apiClient.get('/api/3/ticketes').then(function (response) {
      response.data.forEach(element => {
        var ticket = element.text;

        /// apply cut command
        var cutCode = settings.getSync('2020.cut') ?? '27.105';
        var cutComm = cutCode.split('.');
        if (cutComm.length > 0 && element.cortarpapel) {
          ticket += String.fromCharCode(...cutComm);
        }

        /// apply open command
        var openCode = settings.getSync('2020.open') ?? '27.112.48';
        var openComm = openCode.split('.');
        if (openComm.length > 0 && element.abrircajon) {
          ticket += String.fromCharCode(...openComm);
        }

        /// print
        fs.writeFile("pos.txt", ticket, function(err) {
          if(err) {
            return console.log(err);
          }

          prinTicket(settings.getSync('printer.name'));
        });

        /// delete
        apiClient.delete('/api/3/ticketes/' + element.coddocument);
      });
    })
    .catch(function (error) {
      // handle error
      console.log(error);
    });
  }
  event.reply('timer-2020', 'ok');
})

/// http server
const http = require('http');
const requestListener = function (req, res) {
  res.writeHead(200);
  res.end('fsprinter 0.5.0');
  console.log('http request: ' + req.url);
  if(req.url.substring(0, 12) == '/?documento=') {
    connect2020(req.url.substring(12));
  } else if(req.url.substring(0, 11) == '/?terminal=') {
    connect2017(req.url.substring(2));
  }
}
const server = http.createServer(requestListener);
server.listen(8089);