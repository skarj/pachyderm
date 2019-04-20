# Pachyderm
### Install infrastructure

        cd gcloud
        make install

### Create and fill repository

        make repo

### Create pipelines

        make pipelines

### Check results

        pachctl get-file montage master montage.png | display

### Cleanup

        make clean

### Links

* Helm chart https://github.com/helm/charts/tree/master/stable/pachyderm
* Installation guide https://pachyderm.readthedocs.io/en/stable/deployment/google_cloud_platform.html
* Tutorial https://pachyderm.readthedocs.io/en/stable/getting_started/beginner_tutorial.html
