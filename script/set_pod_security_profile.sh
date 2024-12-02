#!/bin/bash

# Verifica che siano forniti i parametri richiesti
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <namespace> <baseline|restricted>"
  exit 1
fi

NAMESPACE=$1
PROFILE=$2

# Funzione per impostare le etichette PodSecurity
set_pod_security_profile() {
  local namespace=$1
  local profile=$2

  case $profile in
    baseline)
      echo "Setting PodSecurity profile to 'baseline' for namespace '$namespace'..."
      oc label ns "$namespace" pod-security.kubernetes.io/enforce=baseline \
        pod-security.kubernetes.io/audit=baseline \
        pod-security.kubernetes.io/warn=baseline --overwrite
      ;;
    restricted)
      echo "Setting PodSecurity profile to 'restricted' for namespace '$namespace'..."
      oc label ns "$namespace" pod-security.kubernetes.io/enforce=restricted \
        pod-security.kubernetes.io/audit=restricted \
        pod-security.kubernetes.io/warn=restricted --overwrite
      ;;
    *)
      echo "Invalid profile specified. Use 'baseline' or 'restricted'."
      exit 1
      ;;
  esac
}

# Verifica se il namespace esiste
if ! oc get namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "Error: Namespace '$NAMESPACE' does not exist."
  exit 1
fi

# Imposta il profilo di sicurezza
set_pod_security_profile "$NAMESPACE" "$PROFILE"

echo "PodSecurity profile for namespace '$NAMESPACE' set to '$PROFILE'."

