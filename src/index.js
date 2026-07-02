const { ipcRenderer } = require("electron");
const axios = require('axios');
const crypto = require('crypto');

function settingsGet(key) {
  return ipcRenderer.invoke('settings-get', key);
}
function settingsSet(key, value) {
  return ipcRenderer.invoke('settings-set', key, value);
}
function settingsHas(key) {
  return ipcRenderer.invoke('settings-has', key);
}
function settingsUnset() {
  return ipcRenderer.invoke('settings-unset');
}

let wsConnection = null;
let wsReconnectTimeout = null;
let wsConnectionAttempt = 0;
let connectionPingInFlight = false;
let connectionPingQueued = false;
let pollIntervalTimer = null;

const globalState = {
  ws: 'disconnected',
  api: 'idle',
  apiMessage: '',
  apiTime: ''
};

function wsStateLabel(s) {
  switch (s) {
    case 'connected': return 'conectado';
    case 'connecting': return 'conectando…';
    case 'error': return 'error';
    default: return 'desconectado';
  }
}

function apiStateLabel(s, time, message) {
  switch (s) {
    case 'ok': return 'OK (' + time + ')';
    case 'error': return 'error (' + time + ') ' + (message || '');
    default: return 'sin actividad';
  }
}

function renderGlobalStatus() {
  const bar = document.getElementById('global_status_bar');
  const text = document.getElementById('global_status_text');
  if (!bar || !text) {
    return;
  }

  const ws = globalState.ws;
  const api = globalState.api;
  const urlEl = document.getElementById('api_url');
  const hasUrl = urlEl && urlEl.value.trim().length > 0;

  let bg = 'bg-secondary';
  let label = 'Iniciando…';

  if (!hasUrl) {
    bg = 'bg-warning';
    label = 'Rellena la URL de la API para empezar';
  } else if (api === 'error') {
    bg = 'bg-danger';
    label = 'Error de API — no se imprimirán tickets';
  } else if (ws === 'connected') {
    bg = 'bg-success';
    label = 'Listo para imprimir — no cierres esta ventana';
  } else if (ws === 'connecting') {
    bg = 'bg-warning';
    label = 'Conectando…';
  } else if (ws === 'error') {
    bg = 'bg-danger';
    label = 'Sin conexión — no se imprimirán tickets';
  } else {
    bg = 'bg-secondary';
    label = 'Desconectado — configura la API para imprimir';
  }

  bar.className = 'navbar fixed-bottom navbar-light ' + bg;
  text.innerHTML = '<i class="bi bi-circle-fill me-2"></i>' + label;
  bar.title = 'WebSocket: ' + wsStateLabel(ws)
    + '  ·  API: ' + apiStateLabel(api, globalState.apiTime, globalState.apiMessage);
}

function updateWebSocketStatus(status) {
  globalState.ws = status;
  renderGlobalStatus();
}

function updateApiStatus(status, message) {
  globalState.api = status;
  globalState.apiMessage = message || '';
  globalState.apiTime = (status === 'idle') ? '' : new Date().toLocaleTimeString();
  renderGlobalStatus();
}

async function connectionPingOnce() {
  var apiUrl = document.getElementById("api_url").value.trim();
  var apiKey = document.getElementById("api_key").value.trim();

  try {
    const apiClient = await axios.create({ baseURL: apiUrl, headers: { Token: apiKey } });

    // Get printer ID first
    const printerId = await getPrinterId(apiClient, apiKey);
    if (printerId) {
      await printPendingTickets(apiClient, printerId);
    }
    updateApiStatus('ok');
  } catch (err) {
    console.error('connectionPing failed:', err);
    updateApiStatus('error', err && err.message ? err.message : String(err));
  }
}

async function connectionPing() {
  if (connectionPingInFlight) {
    connectionPingQueued = true;
    return;
  }

  connectionPingInFlight = true;

  try {
    do {
      connectionPingQueued = false;
      await connectionPingOnce();
    } while (connectionPingQueued);
  } finally {
    connectionPingInFlight = false;
  }
}

async function getPrinterId(apiClient, apiKey) {
  const resPrinters = await apiClient.get('/api/3/ticketprinteres');

  for (const item of resPrinters.data) {
    if (item.apikey == apiKey) {
      return item.id;
    }
  }
  return null;
}

async function printPendingTickets(apiClient, printerId) {
  // get the latest tickets filtered by printer ID
  const resTickets = await apiClient.get('/api/3/ticketes?filter[printed]=0&filter[idprinter]=' + printerId);
  console.log(resTickets);

  // find the apikey in resPrinters and update lastactivity
  for (const item of resTickets.data) {
    if (item.appversion > 1.0) {
      alert('Por favor, descarga la nueva versión de la app');
      // open a browser window with the app url https://megacity20.com/support/59
      ipcRenderer.send('open-external', 'https://megacity20.com/support/59');
    } else if (item.base64) {
      ipcRenderer.send('send-to-printer', atob(item.body));
    } else {
      ipcRenderer.send('send-to-printer', item.body);
    }

    // set printed to true
    const resPut = await apiClient.put('/api/3/ticketes/' + item.id, 'printed=1');
  }

  // get the printer list
  const resPrinters = await apiClient.get('/api/3/ticketprinteres');

  // find the apikey in resPrinters and update lastactivity and len
  for (const item of resPrinters.data) {
    if (item.apikey == document.getElementById("api_key").value) {
      // get the current date YYYY-MM-DD HH:MM:SS format
      var date = new Date();
      var dateStr = date.getFullYear() + '-' + (date.getMonth() + 1) + '-' + date.getDate()
        + ' ' + date.getHours() + ':' + date.getMinutes() + ':' + date.getSeconds();

      // send put request
      var printerLen = document.getElementById("printer_len").value;
      const resPut = await apiClient.put(
        '/api/3/ticketprinteres/' + item.id,
        'lastactivity=' + dateStr + '&linelen=' + printerLen
      );
    }
  }
}

async function testConnection() {
  var printerName = document.getElementById("printer_list").value;
  var apiUrl = document.getElementById("api_url").value.trim();
  var apiKey = document.getElementById("api_key").value.trim();
  var printerLen = document.getElementById("printer_len").value;

  if (apiUrl.substring(0, 7) != 'http://' && apiUrl.substring(0, 8) != 'https://') {
    alert('URL incorrecta');
    return false;
  } else if (0 == apiKey.length) {
    alert('Se necesita una API key');
    return false;
  }

  try {
    const apiClient = await axios.create({ baseURL: apiUrl, headers: { Token: apiKey } });
    const resPrinters = await apiClient.get('/api/3/ticketprinteres');
    console.log(resPrinters);

    // find the apikey in resPrinters and update lastactivity and len
    for (const item of resPrinters.data) {
      if (item.apikey == apiKey) {
        // get the current date YYYY-MM-DD HH:MM:SS format
        var date = new Date();
        var dateStr = date.getFullYear() + '-' + (date.getMonth() + 1) + '-'
          + date.getDate() + ' ' + date.getHours() + ':' + date.getMinutes() + ':' + date.getSeconds();

        // send put request
        const resPut = await apiClient.put(
          '/api/3/ticketprinteres/' + item.id,
          'lastactivity=' + dateStr + '&linelen=' + printerLen
        );
        console.log(resPut);

        // handle success
        await settingsSet('printer', { name: printerName, len: printerLen });
        await settingsSet('api', { url: apiUrl, key: apiKey });
        alert('La conexión funciona correctamente');
        await printPendingTickets(apiClient, item.id);
        connectWebSocket();
      }
    }
  } catch (err) {
    alert('La conexión falló');
    console.log(err);
  }

  return false;
}

function applyPollInterval() {
  if (pollIntervalTimer) {
    clearInterval(pollIntervalTimer);
    pollIntervalTimer = null;
  }

  const seconds = parseInt(document.getElementById("poll_interval").value, 10) || 0;
  if (seconds > 0) {
    pollIntervalTimer = setInterval(connectionPing, seconds * 1000);
  }
}

async function onPollIntervalChange() {
  const seconds = parseInt(document.getElementById("poll_interval").value, 10) || 0;
  await settingsSet('poll.interval', seconds);
  applyPollInterval();
}

async function testPrinter() {
  await settingsSet('printer', {
    name: document.getElementById("printer_list").value,
    len: document.getElementById("printer_len").value
  });
  ipcRenderer.send('print-test', document.getElementById("printer_list").value);
}

function normalizeApiUrl(rawUrl) {
  const url = new URL(rawUrl.trim());
  url.protocol = url.protocol.toLowerCase();
  url.hostname = url.hostname.toLowerCase();
  if (
    (url.protocol === 'http:' && url.port === '80') ||
    (url.protocol === 'https:' && url.port === '443')
  ) {
    url.port = '';
  }
  let result = url.protocol + '//' + url.host + url.pathname;
  if (result.endsWith('/')) {
    result = result.slice(0, -1);
  }
  return result;
}

function isLocalHostname(hostname) {
  return ['localhost', '127.0.0.1', '[::1]', '::1'].includes(hostname);
}

function connectWebSocket() {
  const rawApiUrl = document.getElementById("api_url").value.trim();
  const apiKey = document.getElementById("api_key").value.trim();

  if (wsReconnectTimeout) {
    clearTimeout(wsReconnectTimeout);
    wsReconnectTimeout = null;
  }

  if (!rawApiUrl) {
    if (wsConnection) {
      wsConnection._intentionalClose = true;
      wsConnection.close();
      wsConnection = null;
    }
    updateWebSocketStatus('disconnected');
    return;
  }

  let apiUrl;
  let hostname;
  try {
    apiUrl = normalizeApiUrl(rawApiUrl);
    hostname = new URL(apiUrl).hostname;
  } catch (err) {
    console.error('Invalid API URL, cannot open WebSocket:', err);
    updateWebSocketStatus('error');
    return;
  }

  // For local URLs the host is ambiguous across installations, so disambiguate
  // with the API key. The server must apply the same rule.
  const channelInput = isLocalHostname(hostname) ? apiUrl + ':' + apiKey : apiUrl;
  const channel = crypto.createHash('md5').update(channelInput).digest('hex');
  const wsUrl = `wss://ai.factura.city/mc20printer/${channel}`;

  console.log('Connecting to WebSocket:', wsUrl);

  // Close existing connection if any
  if (wsConnection) {
    wsConnection._intentionalClose = true;
    wsConnection.close();
  }

  updateWebSocketStatus('connecting');

  try {
    const socket = new WebSocket(wsUrl);
    const attempt = ++wsConnectionAttempt;
    socket._intentionalClose = false;
    wsConnection = socket;

    socket.onopen = function() {
      if (wsConnection !== socket || attempt !== wsConnectionAttempt) {
        socket._intentionalClose = true;
        socket.close();
        return;
      }

      console.log('WebSocket connected');
      updateWebSocketStatus('connected');
    };

    socket.onmessage = function(event) {
      if (wsConnection !== socket || attempt !== wsConnectionAttempt) {
        return;
      }

      console.log('WebSocket message received:', event.data);
      // When a message is received, fetch and print pending tickets
      connectionPing();
    };

    socket.onerror = function(error) {
      if (wsConnection !== socket || attempt !== wsConnectionAttempt) {
        return;
      }

      console.error('WebSocket error:', error);
      updateWebSocketStatus('error');
    };

    socket.onclose = function() {
      if (wsConnection !== socket || attempt !== wsConnectionAttempt) {
        console.log('Ignoring close event from stale WebSocket');
        return;
      }

      wsConnection = null;
      console.log('WebSocket disconnected');
      updateWebSocketStatus('disconnected');

      // Only reconnect if the close was not intentional
      if (!socket._intentionalClose) {
        console.log('Reconnecting in 5 seconds...');
        wsReconnectTimeout = setTimeout(connectWebSocket, 5000);
      } else {
        console.log('Intentional close, not reconnecting');
      }
    };
  } catch (err) {
    wsConnection = null;
    console.error('Failed to connect to WebSocket:', err);
    updateWebSocketStatus('error');
  }
}

// load printer list
ipcRenderer.invoke('get-printers').then(async (printers) => {
  var selectedPrinter = await settingsGet('printer.name');
  printers.map((item) => {
    if (item.name == selectedPrinter) {
      document.getElementById("printer_list").innerHTML +=
        '<option value="' + item.name + '" selected="">' + item.name + '</option>';
    } else {
      document.getElementById("printer_list").innerHTML +=
        '<option value="' + item.name + '">' + item.name + '</option>';
    }
  });
});

// load preferences
(async () => {
  if (await settingsHas('api.url')) {
    document.getElementById("api_url").value = await settingsGet('api.url');
    document.getElementById("api_key").value = await settingsGet('api.key');
    document.getElementById("printer_len").value = await settingsGet('printer.len');
    document.getElementById("reset_btn").classList.remove('d-none');
    connectionPing();
    connectWebSocket();
  } else {
    document.getElementById("printer_len").value = '48';
  }

  if (await settingsHas('poll.interval')) {
    document.getElementById("poll_interval").value = String(await settingsGet('poll.interval'));
  }
  applyPollInterval();
  renderGlobalStatus();
})();

async function resetSettings() {
  if (confirm('¿Estás seguro de que quieres borrar toda la configuración?')) {
    await settingsUnset();
    alert('Configuración borrada. La aplicación se reiniciará.');
    ipcRenderer.send('reload-window');
  }
}
