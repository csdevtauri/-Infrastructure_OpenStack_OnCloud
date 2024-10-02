#!/bin/sh

LOG_FILE=/var/log/install_logs/log_all_installs.json
ERROR_LOG_FILE=/var/log/install_logs/error_log.json

# Fonction pour obtenir l'horodatage actuel
timestamp() {
  timedatectl set-timezone Europe/Paris
  date +"%Y-%m-%dT%H:%M:%S%z"
}

# Fonction pour journaliser les messages
log_info() {
  echo "{\"level\": \"INFO\", \"timestamp\": \"$(timestamp)\", \"message\": \"$1\"}" >> $LOG_FILE
}

log_error() {
  echo "{\"level\": \"ERROR\", \"timestamp\": \"$(timestamp)\", \"message\": \"$1\"}" >> $ERROR_LOG_FILE
}

# Enregistrer les informations d'installation
log_info "== Début de l'enregistrement =="
log_info "Terraform Installation Date: $(date)"
terraform version 2>&1 | while IFS= read -r line; do log_info "$line"; done
log_info "Ansible Installation Date: $(date)"
. /opt/venv/bin/activate && ansible --version 2>&1 | while IFS= read -r line; do log_info "$line"; done && deactivate
