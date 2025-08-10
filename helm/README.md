# **Helm Notes — Table of Contents**

## [**1. Introduction to Helm**](https://github.com/ibtisam-iq/nectar/blob/main/helm/helm-guide.md#section-1--introduction-to-helm)

* What is Helm?
* Why use Helm in Kubernetes?
* Helm vs kubectl
* Helm key concepts (Chart, Release, Repository, Values, Templates)

---

## [**2. Helm Architecture**](https://github.com/ibtisam-iq/nectar/blob/main/helm/helm-guide.md#section-2--helm-architecture)

* Helm v3 workflow (client-side)
* Interaction with Kubernetes API
* Where Helm stores release data in the cluster

---

## [**3. Helm as a Package Manager (Pre-Built Charts)**](https://github.com/ibtisam-iq/nectar/blob/main/helm/helm-guide.md#section-3--helm-as-a-package-manager-pre-built-charts)

* **Definition**: Installing & managing existing charts (apps/controllers)
* Adding a repo (`helm repo add`)
* Searching charts (`helm search repo`)
* Installing from a repo (`helm install release-name repo/chart`)
* Upgrading from a repo (`helm upgrade release-name repo/chart`)
* Uninstalling releases
* Example: Installing ingress-nginx from Bitnami repo
* Example: Upgrading cert-manager from a repo

---

## [**4. Creating & Managing Your Own Application Chart**](https://github.com/ibtisam-iq/nectar/blob/main/helm/helm-guide.md#section-4-creating--managing-your-own-application-chart)

* Creating a chart (`helm create`)
* Chart directory structure explained
* Editing templates & values
* Installing your own chart locally
* Upgrading your own chart locally
* Packaging your chart (`helm package`)
* Hosting your chart in a repo
* Installing from your own repo
* Example: MyApp chart with upgrade

---

## [**5. Chart Values & Customization**](https://github.com/ibtisam-iq/nectar/blob/main/helm/helm-guide.md#section-5-chart-values--customization)

* Purpose of `values.yaml`
* Overriding values during install

  * `--set key=value`
  * `-f my-values.yaml`
* Combining multiple values files
* Example: Customizing image and replicas

---

## [**6. Release Management**](https://github.com/ibtisam-iq/nectar/blob/main/helm/helm-guide.md#section-6--upgrading-rolling-back--uninstalling-releases)

* Listing releases (`helm list`)
* Viewing release details (`helm status`)
* Upgrading (`helm upgrade`)
* Rolling back (`helm rollback`)
* Uninstalling (`helm uninstall`)
* Example: Rollback after a failed upgrade

---

## **7. Helm Template Engine**

* Template basics
* Go templating syntax
* `_helpers.tpl` usage
* Example: Dynamic Deployment YAML

---

## [**8. Troubleshooting Helm**](https://github.com/ibtisam-iq/nectar/blob/main/helm/helm-guide.md#section-8--troubleshooting-helm)

* `--dry-run` and `--debug`
* Viewing rendered manifests before install (`helm template`)
* Common errors and solutions

---

## [**9. Helm in CKA Exam Context**](https://github.com/ibtisam-iq/nectar/blob/main/helm/helm-guide.md#section-9--helm-in-cka-exam-context)

* Common scenarios in the exam
* Fast installation tricks
* Repo management under time pressure

---

## **10. Helm Quick Reference**

* Most used commands
* Common flags
* Flow diagrams for both use cases:

  * Installing from repo
  * Creating & installing your own chart










