# Installing Cloud Pak for Data using ArgoCD

## Author
Luigi Molinaro (luigi.molinaro@ibm.com)

# Installation

## Contents

- [Installation](#installation)
  - [Contents](#contents)
  - [Prerequisites](#prerequisites)
  - [Install the OpenShift GitOps operator](#install-the-openshift-gitops-operator)
    - [Using the OCP console](#using-the-ocp-console)
    - [Using a terminal](#using-a-terminal)
  - [Obtain an entitlement key](#obtain-an-entitlement-key)
  - [Update the OCP global pull secret](#update-the-ocp-global-pull-secret)
    - [Update the global pull secret using the OpenShift console](#update-the-global-pull-secret-using-the-openshift-console)
    - [Special note about global pull secrets on ROKS](#special-note-about-global-pull-secrets-on-roks)
  - [Update the pull secret in the openshift-gitops namespace](#update-the-pull-secret-in-the-openshift-gitops-namespace)
  - [Adding Cloud Pak GitOps Application objects to your GitOps server](#adding-cloud-pak-gitops-application-objects-to-your-gitops-server)
    - [Using the OCP console](#using-the-ocp-console-1)
    - [Using a terminal](#using-a-terminal-1)
  - [Post-configuration steps](#post-configuration-steps)
    - [Local configuration steps](#local-configuration-steps)
      - [Cloud Pak for Data](#cloud-pak-for-data)
      - [Cloud Pak for Integration](#cloud-pak-for-integration)
  - [Duplicate this repository](#duplicate-this-repository)

---

## Prerequisites

- OpenShift >=4.12
- ARGOCD  (https://argocd-operator.readthedocs.io/en/latest/install/openshift/)
- Openshift CLI 

---

## Install the OpenShift GitOps operator

### Using the OCP console

1. From the Administrator's perspective, navigate to the OperatorHub page.

2. Search for "Red Hat OpenShift GitOps." Click on the tile and then click on "Install."

![image](https://github.com/user-attachments/assets/57521b29-1e5a-4f3c-8eb6-0f8dcab336e8)

3. Keep the defaults in the wizard and click on "Install."

4. Wait for it to appear in the " Installed Operators list." If it doesn't install correctly, you can check its status on the "Installed Operators" page.

### Using a terminal

1. Login to the OpenShift using CLI

1. Create the `Subscription` resource for the operator:

   ```sh
   cat << EOF | oc apply -f -
   ---
   apiVersion: operators.coreos.com/v1alpha1
   kind: Subscription
   metadata:
      name: openshift-gitops-operator
      namespace: openshift-operators
   spec:
      channel: latest
      installPlanApproval: Automatic
      name: openshift-gitops-operator
      source: redhat-operators
      sourceNamespace: openshift-marketplace
   EOF
   ```

   Wait until the ArgoCD instance appears as ready in the `openshift-gitops` namespace.

   ```sh
    oc wait ArgoCD openshift-gitops \
        -n openshift-gitops \
        --for=jsonpath='{.status.phase}'=Available \
        --timeout=600s
   ```
---

## Obtain an entitlement key

If you don't already have an entitlement key to the IBM Entitled Registry, obtain your key using the following instructions:

1. Go to the [Container software library](https://myibm.ibm.com/products-services/containerlibrary).

1. Click the "Copy key."

1. Copy the entitlement key to a safe place to update the cluster's global pull secret.

1. (Optional) Verify the validity of the key by logging in to the IBM Entitled Registry using a container tool:

podman : 

   ```sh
   export IBM_ENTITLEMENT_KEY=the key from the previous steps
   podman login cp.icr.io --username cp --password "${IBM_ENTITLEMENT_KEY}"
   ```
docker :

  ```sh
   export IBM_ENTITLEMENT_KEY=the key from the previous steps
   docker login cp.icr.io --username cp --password "${IBM_ENTITLEMENT_KEY}"
   ```

Important: The following examples will use Podman as it is the preferred container runtime for IBM. If you choose to use Docker instead, ensure you adjust the configuration to match your setup or create an alias like

  ```sh
  alias podman="docker"
   ```

---

## Update the OCP global pull secret

Update the OCP global pull secret with the entitlement key.

### Update the global pull secret using the OpenShift console

1. Navigate to the "Workloads > Secrets" in namespace "openshift-config"

1. Select the object "pull-secret."

1. Click on "Actions -> Edit secret."

1. Scroll to the bottom of that page and click on "Add credentials," using the following values for each field:

   - "Registry Server Address" cp.icr.io
   - "Username": cp
   - "Password": paste the entitlement key you copied from the [Obtain an entitlement key](#obtain-an-entitlement-key) 
   - "Email": any email, valid or not, will work. This field is mostly a hint to other people who may see the entry in the configuration

1. Click on "Save."

At the end you have something like that : 

![image](https://github.com/user-attachments/assets/82a7d295-0645-426e-8276-059d776b842c)

---

## Update the pull secret in the openshift-gitops namespace

Global pull secrets require granting too much privilege to the OpenShift GitOps service account, so we have started transitioning to the definition of pull secrets at a namespace level.

The Application resources are transitioning to use `PreSync` hooks to copy the entitlement key from a `Secret` named `ibm-entitlement-key` in the `openshift-gitops` namespace, so issue the following command to create that secret:

```sh
oc create secret docker-registry ibm-entitlement-key \
        --docker-server=cp.icr.io \
        --docker-username=cp \
        --docker-password="${IBM_ENTITLEMENT_KEY}" \
        --docker-email="non-existent-replace-with-yours@email.com" \
        --namespace=openshift-gitops
```
Expected output : 

![image](https://github.com/user-attachments/assets/aaff71ff-6ae9-4ef1-8487-f71ede0002c7)

---

## Adding Cloud Pak GitOps Application objects to your GitOps server

![image](https://github.com/user-attachments/assets/5e764265-9a2d-4a94-9d5e-5e3a359fbf0a)


### Using the OCP console

1. Launch the Argo CD console: Click on the grid-like icon in the upper-left section of the screen, where you should click on "Cluster Argo CD."


## Login

1. The Argo CD login screen will prompt you for an admin user and password. We can login trought Openshift "LOG IN VIA OPENSHIFT" or trought admin/password : the default user is `admin .` The admin password is located in secret `openshift-gitops-cluster` in the `openshift-gitops` namespace.

   - Switch to the `openshift-gitops` project, locate the secret in the "Workloads -> Secrets" selections in the left-navigation tree of the Administrator view, scroll to the bottom, and click on "Reveal Values" to retrieve the value of the `admin.password` field.

   - Type in the user and password listed in the previous steps, and click the "Sign In" button.

## Configure 

1. (add Argo app) Once logged to the Argo CD console, click on the "New App+" button in the upper left of the Argo CD console and fill out the form with values matching the Cloud Pak of your choice, according to the table below:

    For all other fields, use the following values:

    | Field | Value |
    | ----- | ----- |
    | Application Name | argo-app |
    | Path | config/argocd |
    | Namespace | openshift-gitops |
    | Project | default |
    | Sync policy | Automatic |
    | Self Heal | true |
    | Repository URL | <https://github.com/IBM/cloudpak-gitops> |
    | Revision | HEAD |
    | Cluster URL | <https://kubernetes.default.svc> |

1. (add Cloud Pak Shared app) Click on the "New App+" button again and fill out the form with values matching the Cloud Pak of your choice, according to the table below:

    For all other fields, use the following values:

    | Field | Value |
    | ----- | ----- |
    | Application Name | cp-shared-app |
    | Path | config/argocd-cloudpaks/cp-shared |
    | Namespace | ibm-cloudpaks |
    | Project | default |
    | Sync policy | Automatic |
    | Self Heal | true |
    | Repository URL | <https://github.com/IBM/cloudpak-gitops> |
    | Revision | HEAD |
    | Cluster URL | <https://kubernetes.default.svc> |

    **Optional**: If you want to deploy Cloud Pak for Integration or Cloud Pak for Security to a non-default namespace, you must override the default value for the Cloud Paks, using the parameters below:

    | Parameter | (Default) Value |
    | --------- | --------------- |
    | dedicated_cs.enabled | true |
    | dedicated_cs.namespace_mapping.cp4i | cp4i |
    | dedicated_cs.namespace_mapping.cp4s | cp4s |

    Note that Cloud Pak for Data and Cloud Pak for Business Automation do not have this setting - because they enable dedicated Foundation Service namespace by default. Cloud Pak for AIOps does not have this setting either, because it does not support dedicated Foundation Service namespaces.

2. After filling out the form details, click the "Create" button

3. (add actual Cloud Pak) Click on the "New App+" button again and fill out the form with values matching the Cloud Pak of your choice, according to the table below:

    Note that if you want to deploy a Cloud Pak to a non-default namespace, you need to make sure you pass the same namespace values used in the optional parameter values for the `cp-shared` application.

    | Cloud Pak | Application Name | Path | Namespace |
    | --------- | ---------------- | ---- | --------- |
    | Business Automation | cp4a-app | config/argocd-cloudpaks/cp4a | cp4a |
    | Data | cp4d-app | config/argocd-cloudpaks/cp4d | cp4d |
    | Integration | cp4i-app | config/argocd-cloudpaks/cp4i | cp4i |
    | Security | cp4s-app | config/argocd-cloudpaks/cp4s | cp4s |
    | AIOps | cp4aiops-app | config/argocd-cloudpaks/cp4aiops | cp4aiops |

    For all other fields, use the following values:

    | Field | Value |
    | ----- | ----- |
    | Project | default |
    | Sync policy | Automatic |
    | Self Heal | true |
    | Repository URL | <https://github.com/IBM/cloudpak-gitops> |
    | Revision | HEAD |
    | Cluster URL | <https://kubernetes.default.svc> |

4. After filling out the form details, click the "Create" button

5. Under "Parameters," set the values for the fields `storageclass.rwo` and `storageclass.rwx` with the appropriate storage classes. For OpenShift Container Storage, the values will be `ocs-storagecluster-ceph-rbd` and `ocs-storagecluster-cephfs`, respectively.

6. After filling out the form details, click the "Create" button

7. Wait for the synchronization to complete.

### Using a terminal

1. Open a terminal and ensure you have the OpenShift CLI installed:

   ```sh
   oc version --client

   # Client Version: 4.10.60
   ```

   Ideally, the client's minor version should be at most one iteration behind the server version. Most commands here are pretty basic and will work with more significant differences, but keep that in mind if you see errors about unrecognized commands and parameters.

   If you do not have the CLI installed, follow [these instructions](https://docs.openshift.com/container-platform/4.7/cli_reference/openshift_cli/getting-started-cli.html).

1. [Login to the OpenShift CLI](https://docs.openshift.com/container-platform/4.7/cli_reference/openshift_cli/getting-started-cli.html#cli-logging-in_cli-developer-commands)

1. [Install the Argo CD CLI](https://argoproj.github.io/argo-cd/cli_installation/)

1. Log in to the Argo CD server

   ```sh
   gitops_url=https://github.com/IBM/cloudpak-gitops
   gitops_branch=main
   argo_pwd=$(oc get secret openshift-gitops-cluster \
                  -n openshift-gitops \
                  -o go-template='{{index .data "admin.password"|base64decode}}') \
   && argo_url=$(oc get route openshift-gitops-server \
                  -n openshift-gitops \
                  -o jsonpath='{.spec.host}') \
   && argocd login "${argo_url}" \
         --username admin \
         --password "${argo_pwd}" \
         --insecure
   ```

1. Add the `argo` application. (this step assumes you still have the shell variables assigned from previous actions) :

   ```sh
   argocd proj create argocd-control-plane \
         --dest "https://kubernetes.default.svc,openshift-gitops" \
         --src ${gitops_url:?} \
         --upsert \
   && argocd app create argo-app \
         --project argocd-control-plane \
         --dest-namespace openshift-gitops \
         --dest-server https://kubernetes.default.svc \
         --repo ${gitops_url:?} \
         --path config/argocd \
         --helm-set-string targetRevision="${gitops_branch}" \
         --revision ${gitops_branch:?} \
         --sync-policy automated \
         --upsert \
   && argocd app wait argo-app
   ```

1. Add the `cp-shared` application. (this step assumes you still have the shell variables assigned from previous steps) :

   ```sh
   cp_namespace=ibm-cloudpaks

   # Switch to true if you want to use Red Hat Cert Manager instead of 
   # IBM Cert Manager.
   #
   # ** This is only supported for CP4BA and CP4D **
   #
   red_hat_cert_manager=false

   # If you want to override the default target namespace for 
   # Cloud Pak for Security, you need to adjust the values below
   # to indicate the desired target namespace.
   #
   dedicated_cs_enabled=false

   cp4s_namespace=cp4s

   argocd app create cp-shared-app \
         --project default \
         --dest-namespace openshift-gitops \
         --dest-server https://kubernetes.default.svc \
         --repo ${gitops_url:?} \
         --path config/argocd-cloudpaks/cp-shared \
         --helm-set-string argocd_app_namespace="${cp_namespace}" \
         --helm-set-string metadata.argocd_app_namespace="${cp_namespace}" \
         --helm-set-string red_hat_cert_manager="${red_hat_cert_manager:-false}" \
         --helm-set-string dedicated_cs.enabled="${dedicated_cs_enabled:-false}" \
         --helm-set-string dedicated_cs.namespace_mapping.cp4s="${cp4s_namespace:-cp4s}" \
         --helm-set-string targetRevision="${gitops_branch:?}" \
         --revision ${gitops_branch:?} \
         --sync-policy automated \
         --upsert
   ```

1. Add the respective Cloud Pak application (this step assumes you still have shell variables assigned from previous steps) :

   ```sh
   # Choose a value from the "Application Name" column in the 
   # table of Cloud Paks above, such as cp4a, cp4i, or cp4d
   cp=cp4i

   # Note that if you want to use a target namespace that is not the
   # default, you must make the corresponding parameter update to the
   # cp-shared-app application.
   cp_namespace=$cp

   app_name=${cp}-app
   # app_path=<< choose the respective value from the "path name." 
   # column in the table of Cloud Paks above, such as 
   # config/argocd-cloudpaks/cp4a, config/argocd-cloudpaks/cp4i, 
   # etc
   app_path=config/argocd-cloudpaks/${cp}

   argocd app create "${app_name}" \
         --project default \
         --dest-namespace openshift-gitops \
         --dest-server https://kubernetes.default.svc \
         --helm-set-string metadata.argocd_app_namespace="${cp_namespace:?}" \
         --helm-set-string repoURL=${gitops_url:?} \
         --helm-set-string targetRevision="${gitops_branch}" \
         --path "${app_path}" \
         --repo ${gitops_url:?} \
         --revision "${gitops_branch}" \
         --sync-policy automated \
         --upsert 
    ```

1. List all the applications to see their overall status (this step assumes you still have shell variables assigned from previous steps):

   ```sh
   argocd app list -l app.kubernetes.io/instance=${app_name}
   ```

1. You can also use the Argo CD command-line interface to wait for the application to be synchronized and healthy:

   ```sh
   argocd app wait "${app_name}" \
         --sync \
         --health \
         --operation \
         --timeout 3600
   ```

---

## Post-configuration steps

In a GitOps practice, the "post-configuration" phase would entail committing changes to the repository and waiting for the GitOps operator to synchronize those settings toward the target environments.

### Local configuration steps

This repository allows some light customizations to enable its reuse for demonstration purposes without requiring the cloning or forking of the repository.

#### Cloud Pak for Data

The main Argo Application for the Cloud Pak (`config/argocd-cloudpaks/cp4d`) has a parameter named `components`, which contains a comma-separated list of components names matching the values in the [product documentation](https://www.ibm.com/docs/en/cloud-paks/cp-data/4.8.x?topic=information-determining-which-components-install).

Alter the values in this array with the element names found in the product documentation (e.g., `wml` for Watson Machine Learning) to define the list of components installed in the target cluster.

#### Cloud Pak for Integration

The main Argo Application for the Cloud Pak (`config/argocd-cloudpaks/cp4i`) has a parameter array named `modules`, where you will find boolean values for various modules, such as `apic`, `mq`, and `platform`.

Set those values to `true` or `false` to define which Cloud Pak modules you want to install in the target cluster.

---

## Duplicate this repository

Given the demonstration purposes of this repository, it is unsuited for anchoring a true GitOps deployment for many reasons. The primary limitation is the repository not being designed to represent any concrete deployment environment (e.g., there is no environment-specific folder where you could list the Cloud Pak components for a specific cluster.)

In that sense, you can duplicate the repository on a different Git organization and use that repository as the starting point to deploy Cloud Paks in your environments. This is a non-comprehensive list of aspects you should address in that new repository:

- If you already have the OpenShift GitOps operator installed in your target clusters:
   1. Merge the `.spec.resourceCustomizations` resources found in `argocd/templates/argocd.yaml` into the `ArgoCD.argoproj.io` instance for your cluster
   1. Delete the entire folder `/argocd`
- Delete folders corresponding to Cloud Paks you don't plan on using. These Cloud Pak folders are located under the `/config/argocd-cloudpaks` and `/config` folders.
