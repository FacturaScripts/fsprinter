const { app, BrowserWindow } = require('electron');
const { exec } = require('child_process');
const fs = require('fs');
const os = require('os');

function createWindow () {
    const win = new BrowserWindow({
      width: 900,
      height: 600,
      webPreferences: {
        contextIsolation: false,
        enableRemoteModule: true,
        nodeIntegration: true
      }
    })
  
    win.removeMenu();
    win.webContents.openDevTools();
    win.loadFile('src/index.html');
  }

function prinTicket() {
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

        var printCmd = "lp -d POS58 pos.txt";
        if(os.platform() == 'win32') {
            printCmd = 'RawPrint.exe "TPV" pos.txt';
        }

        exec(printCmd, (error, stdout, stderr) => {
            if (error) {
                console.log(`error: ${error.message}`);
                return;
            }
            if (stderr) {
                console.log(`stderr: ${stderr}`);
                return;
            }
            console.log(`stdout: ${stdout}`);
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