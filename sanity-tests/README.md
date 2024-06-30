# Sanity tests for the agent helm chart

It runs the `helm install --dry-run -f ./default.values.yaml,<values file>` command for each yaml file in `test-cases` directory. The `values` file is the `values.yaml` file in the `test-cases` directory.
Dry run validates the rendered k8s manifests using schema from the actual k8s cluster, so you need cluster credentials available (works with local cluster too).
It does not deploy the resources to the cluster.

To add a new test create a new file in the `test-cases` directory and helm values as needed.

To manually run single test run the following command:
```bash
helm install agent ../ --dry-run -f ./default.values.yaml,./test-cases/strict-security.values.yaml
```
