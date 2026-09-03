const { app, BrowserWindow, dialog, ipcMain, shell } = require('electron');
const { exec, execFile } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');
const settings = require('electron-settings');

app.commandLine.appendSwitch('no-sandbox');

var win = null;

// hosts permitidos para la descarga de actualizaciones desde download-update
const ALLOWED_UPDATE_HOSTS = new Set(['github.com', 'objects.githubusercontent.com', 'facturascripts.com']);

function createWindow() {
  win = new BrowserWindow({
    width: 430,
    height: 550,
    webPreferences: {
      contextIsolation: false,
      nodeIntegration: true
    }
  })

  win.removeMenu();
  //win.webContents.openDevTools();
  win.loadFile('src/index.html');
}

function prinTesTicket(printerName) {
  var esc = '\x1B'; //ESC byte in hex notation
  var gs = '\x1D'; //GS byte in hex notation
  var newLine = '\x0A'; //LF byte in hex notation
  var cmds = esc + "@"; //Initializes the printer (ESC @)

  // Header
  cmds += esc + '!' + '\x38'; //Emphasized + Double-height + Double-width mode selected (ESC ! (8 + 16 + 32)) 56 dec => 38 hex
  cmds += 'PRUEBA'; //text to print
  cmds += newLine + newLine;
  cmds += esc + '!' + '\x00'; //Character font A selected (ESC ! 0)

  // Sample items
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
  cmds += newLine + newLine;

  // Print barcode - Code128
  cmds += esc + 'a' + '\x01'; // Center alignment
  cmds += 'CODIGO DE BARRAS:';
  cmds += newLine;
  cmds += gs + 'h' + '\x50'; // Set barcode height to 80 dots
  cmds += gs + 'w' + '\x02'; // Set barcode width to 2
  cmds += gs + 'H' + '\x02'; // Print HRI (human readable) below barcode
  cmds += gs + 'k' + '\x49' + '\x0D' + '1234567890123'; // CODE128 barcode with content
  cmds += newLine + newLine;

  // Print QR Code
  cmds += 'CODIGO QR:';
  cmds += newLine;
  // QR Code: Model
  cmds += gs + '(k' + '\x04\x00' + '1A2\x00'; // Function 165: Set model (49=1, 50=2)
  // QR Code: Size
  cmds += gs + '(k' + '\x03\x00' + '1C' + '\x08'; // Function 167: Set size to 8
  // QR Code: Error correction level
  cmds += gs + '(k' + '\x03\x00' + '1E0'; // Function 169: Error correction L
  // QR Code: Store data
  var qrData = 'https://megacity20.com';
  var qrDataLength = qrData.length + 3;
  var pL = String.fromCharCode(qrDataLength % 256);
  var pH = String.fromCharCode(Math.floor(qrDataLength / 256));
  cmds += gs + '(k' + pL + pH + '1P0' + qrData; // Function 180: Store data
  // QR Code: Print
  cmds += gs + '(k' + '\x03\x00' + '1Q0'; // Function 181: Print QR code
  cmds += newLine + newLine;

  // Reset alignment
  cmds += esc + 'a' + '\x00'; // Left alignment
  cmds += newLine + newLine;

  // add cut command (ESC m - partial cut)
  cmds += '\x1B\x6D' + newLine;

  // add cash drawer open command (ESC p 0 55 121 - standard command)
  cmds += '\x1B\x70\x30\x37\x79' + newLine;

  const ticketPath = path.join(app.getPath('temp'), 'fsprinter_ticket');
  // 'binary' evita que Node reinterprete como UTF-8 los bytes ESC/POS > 127
  // (código de barras, QR), que deben viajar tal cual a la impresora.
  fs.writeFile(ticketPath, cmds, 'binary', function (err) {
    if (err) {
      return console.log(err);
    }

    prinTicket(printerName, function (err, statusMessage) {
      if (err) {
        dialog.showErrorBox('Error al imprimir', err.message);
        return;
      }

      dialog.showMessageBox(win, {
        type: 'info',
        title: 'Prueba de impresión',
        message: 'Trabajo enviado a la impresora.',
        detail: statusMessage
      });
    });
  });

  // volcamos en consola la ruta del archivo
  console.log('Ticket file path:', ticketPath);
}

function checkPrinterQueue(printerName, callback) {
  execFile('lpstat', ['-p', printerName], (error, stdout) => {
    if (error) {
      // lpstat no disponible (p.ej. Windows) o impresora no encontrada en CUPS
      return callback(null);
    }

    const status = stdout.trim();
    if (/desactivada|disabled/i.test(status)) {
      return callback(new Error('La cola de la impresora está desactivada en el sistema. ' +
        'Revisa la conexión USB y reactívala (cupsenable "' + printerName + '") o desde Preferencias del Sistema > Impresoras.'));
    }

    callback(null, status);
  });
}

function prinTicket(printerName, callback) {
  const ticketPath = path.join(app.getPath('temp'), 'fsprinter_ticket');
  let printCmd;

  if (os.platform() == 'win32') {
    // Get the resources path properly
    let resourcesPath;
    if (app.isPackaged) {
      // When packaged, unpacked files are in app.asar.unpacked
      resourcesPath = path.join(process.resourcesPath, 'app.asar.unpacked');
    } else {
      // In development, use the app path directly
      resourcesPath = app.getAppPath();
    }

    const rawPrintPath = path.join(resourcesPath, 'RawPrint.exe');
    printCmd = '"' + rawPrintPath + '" "' + printerName + '" "' + ticketPath + '"';
  } else if (os.platform() == 'darwin') {
    // macOS: usar lp con ruta absoluta
    printCmd = 'lp -d "' + printerName + '" -o raw "' + ticketPath + '"';
  } else {
    // Linux
    printCmd = 'lp -d "' + printerName + '" "' + ticketPath + '"';
  }

  console.log('Print command:', printCmd);

  exec(printCmd, (error, stdout, stderr) => {
    if(stdout) {
      console.log(`stdout: ${stdout}`);
    }
    if (error) {
      console.log(`error: ${error.message}`);
      if (typeof callback === 'function') return callback(error);
      dialog.showErrorBox("print error", error.message);
      return;
    }
    if (stderr) {
      console.log(`stderr: ${stderr}`);
      if (typeof callback === 'function') return callback(new Error(stderr));
      return;
    }

    if (os.platform() !== 'darwin' && os.platform() !== 'linux') {
      // lpstat solo aplica a colas CUPS (macOS/Linux)
      if (typeof callback === 'function') callback(null);
      return;
    }

    checkPrinterQueue(printerName, function (err, status) {
      if (typeof callback === 'function') callback(err, status);
      else if (err) console.log(err.message);
    });
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

ipcMain.handle('get-printers', async () => {
  return await win.webContents.getPrintersAsync();
})

ipcMain.on('open-external', (event, url) => {
  shell.openExternal(url);
})

ipcMain.on('reload-window', () => {
  if (win) win.reload();
})

ipcMain.handle('settings-get', async (event, key) => {
  return await settings.get(key);
})

ipcMain.handle('settings-set', async (event, key, value) => {
  return await settings.set(key, value);
})

ipcMain.handle('settings-has', async (event, key) => {
  return await settings.has(key);
})

ipcMain.handle('settings-unset', async () => {
  return await settings.unset();
})

ipcMain.handle('get-app-version', () => app.getVersion())

// descarga el instalador de una nueva versión a la carpeta de Descargas,
// notificando el progreso al renderer, y lo abre automáticamente al terminar
ipcMain.handle('download-update', async (event, downloadUrl) => {
  let parsedUrl;
  try {
    parsedUrl = new URL(downloadUrl);
  } catch (err) {
    throw new Error('URL de descarga inválida');
  }

  if (parsedUrl.protocol !== 'https:' || !ALLOWED_UPDATE_HOSTS.has(parsedUrl.hostname)) {
    throw new Error('Host de descarga no permitido: ' + parsedUrl.hostname);
  }

  const fileName = path.basename(parsedUrl.pathname);
  const destPath = path.join(app.getPath('downloads'), fileName);

  const response = await fetch(downloadUrl);
  if (!response.ok || !response.body) {
    throw new Error('No se pudo descargar el fichero (' + response.status + ')');
  }

  const totalBytes = parseInt(response.headers.get('content-length') || '0', 10);
  let receivedBytes = 0;

  const fileStream = fs.createWriteStream(destPath);
  const reader = response.body.getReader();

  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) {
        break;
      }

      receivedBytes += value.length;
      fileStream.write(Buffer.from(value));

      if (totalBytes > 0 && win) {
        win.webContents.send('download-progress', Math.round((receivedBytes / totalBytes) * 100));
      }
    }
  } finally {
    fileStream.end();
  }

  await new Promise((resolve, reject) => {
    fileStream.on('finish', resolve);
    fileStream.on('error', reject);
  });

  const openError = await shell.openPath(destPath);
  if (openError) {
    throw new Error('No se pudo abrir el instalador: ' + openError);
  }

  // el instalador necesita sobrescribir los ficheros de la app, así que hay
  // que cerrarla; se espera un momento para que el instalador termine de arrancar
  setTimeout(() => app.quit(), 2000);

  return destPath;
})

ipcMain.on('print-test', (event, arg) => {
  prinTesTicket(arg);
  event.reply('print-test', 'ok');
})

ipcMain.on('send-to-printer', (event, arg) => {
  console.log('send-to-printer');

  const ticketPath = path.join(app.getPath('temp'), 'fsprinter_ticket');
  var text = '\x1B' + '@' + arg;
  fs.writeFile(ticketPath, text, 'binary', function (err) {
    if (err) {
      return console.log(err);
    }

    prinTicket(settings.getSync('printer.name'), function (err) {
      if (err) console.log(err.message);
    });
  });

  event.reply('send-to-printer', 'ok');
})
