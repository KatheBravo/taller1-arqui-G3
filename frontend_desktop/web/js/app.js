// Estado de la aplicacion en el cliente
let currentPollId = "1";
let hasVotedInSession = false;

// Elementos del DOM
const pollTitleEl = document.getElementById("poll-title");
const pollDescriptionEl = document.getElementById("poll-description");
const pollStatusEl = document.getElementById("poll-status");
const totalVotesEl = document.getElementById("total-votes");
const alertBannerEl = document.getElementById("alert-banner");
const statusBadgeEl = document.getElementById("status-badge");
const statusTextEl = document.getElementById("status-text");

// 1. Funciones expuestas a Python via Eel (Server Push)

eel.expose(set_terminal_id);
function set_terminal_id(nodeId) {
  const badgeEl = document.getElementById("terminal-badge");
  if (badgeEl && nodeId) {
    badgeEl.textContent = `Terminal ID: ${nodeId}`;
  }
}

eel.expose(set_connection_status);
function set_connection_status(isConnected, text, nodeId) {
  if (isConnected) {
    statusBadgeEl.className = "status-badge";
    statusTextEl.textContent = text || "Conectado a Rails / ActionCable";
  } else {
    statusBadgeEl.className = "status-badge disconnected";
    statusTextEl.textContent = text || "Desconectado (Reconectando...)";
  }
  if (nodeId) {
    set_terminal_id(nodeId);
  }
}

eel.expose(update_poll_state);
function update_poll_state(data) {
  if (!data) return;

  const poll = data.poll || {};
  currentPollId = poll.id || "1";

  if (pollTitleEl) pollTitleEl.textContent = poll.title || "Votacion en Vivo";
  if (pollDescriptionEl) pollDescriptionEl.textContent = poll.description || "";
  if (pollStatusEl) {
    pollStatusEl.textContent = poll.status === "open" ? "Sesion Abierta" : "Sesion Cerrada";
  }

  // Actualizar totales si vienen incluidos
  if (data.totals && data.percentages) {
    applyTotals(data.totals, data.percentages, data.total_votes);
  }
}

eel.expose(update_results);
function update_results(payload) {
  if (!payload) return;
  const totals = payload.totals || {};
  const percentages = payload.percentages || {};
  const totalVotes = payload.total_votes || 0;

  applyTotals(totals, percentages, totalVotes);
}

function applyTotals(totals, percentages, totalVotes) {
  if (totalVotesEl) {
    totalVotesEl.textContent = `${totalVotes} votos emitidos`;
  }

  // Actualizar cada barra y contador
  for (const [optId, votes] of Object.entries(totals)) {
    const pct = percentages[optId] !== undefined ? percentages[optId] : 0;
    const barEl = document.getElementById(`bar-${optId}`);
    const countEl = document.getElementById(`count-${optId}`);

    if (barEl) {
      barEl.style.width = `${pct}%`;
    }
    if (countEl) {
      countEl.textContent = `${votes} votos (${pct}%)`;
    }
  }
}

eel.expose(on_vote_accepted);
function on_vote_accepted(payload) {
  hasVotedInSession = true;
  showAlert("success", "Tu voto ha sido registrado correctamente y procesado en Redis.");
  disableVoteButtons();
}

eel.expose(on_vote_error);
function on_vote_error(errorMessage) {
  showAlert("error", errorMessage || "No fue posible registrar el voto.");
}

// 2. Eventos de la Interfaz de Usuario

function onVoteClick(optionId) {
  if (hasVotedInSession) {
    showAlert("error", "Ya has emitido tu voto desde este terminal.");
    return;
  }

  // Invocar funcion Python expuesta via Eel
  eel.send_vote(currentPollId, optionId)();
}

function onResetClick() {
  if (confirm("Deseas reiniciar los contadores de la votacion para una nueva prueba?")) {
    hasVotedInSession = false;
    enableVoteButtons();
    hideAlert();
    eel.reset_session(currentPollId)();
  }
}

function showAlert(type, message) {
  if (!alertBannerEl) return;
  alertBannerEl.className = `alert-banner ${type}`;
  alertBannerEl.textContent = message;
}

function hideAlert() {
  if (!alertBannerEl) return;
  alertBannerEl.className = "alert-banner";
  alertBannerEl.style.display = "none";
}

function disableVoteButtons() {
  const buttons = document.querySelectorAll(".vote-btn");
  buttons.forEach(btn => {
    btn.disabled = true;
    if (!btn.dataset.origText) {
      btn.dataset.origText = btn.textContent;
    }
    btn.textContent = "Voto Registrado";
  });
}

function enableVoteButtons() {
  const buttons = document.querySelectorAll(".vote-btn");
  buttons.forEach(btn => {
    btn.disabled = false;
    if (btn.dataset.origText) {
      btn.textContent = btn.dataset.origText;
    }
  });
}

function requestInitialData() {
  if (window.eel && typeof eel.request_initial_state === "function") {
    eel.request_initial_state()();
  }
}

// Al cargar el documento, solicitar datos iniciales a Python
document.addEventListener("DOMContentLoaded", () => {
  requestInitialData();
  setTimeout(requestInitialData, 300);
  setTimeout(requestInitialData, 1000);
});
