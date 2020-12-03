let { remote } = require("electron");
let printers = remote.getCurrentWebContents().getPrinters();
console.log(printers);

printers.map((item, index) => {
    //write in the screen the printers for choose
    document.getElementById("printer_list").innerHTML +=
      '<option value="' + item.name + '">' + item.name + '</option>';
});

function prinTest() {
  alert('test');
}

function test2017() {
  alert('test 2017');
}

function test2020() {
  alert('test 2020');
}