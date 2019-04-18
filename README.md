# Installation

*  Install **Helm**

        kubectl apply -f gcloud/helm/helm-tiller
        helm init --service-account tiller

*  Install **Pachyderm**

        helm install stable/pachyderm --name pachyderm --namespace pachyderm -f gcloud/helm/values.yaml

    https://github.com/helm/charts/tree/master/stable/pachyderm


*  Install **Pachyderm client**

        curl -o /tmp/pachctl.deb -L https://github.com/pachyderm/pachyderm/releases/download/v1.8.6/pachctl_1.8.6_amd64.deb && sudo dpkg -i /tmp/pachctl.deb

        pachctl --namespace=pachyderm port-forward &
