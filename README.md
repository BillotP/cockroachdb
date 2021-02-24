```bash
#!/usr/bin/env bash
# exit when any command fails
set -e
```
##           BEFORE INSTALL

#### Install cockroach cli

- `mkdir certs my-safe-directory`

- `wget -qO- https://binaries.cockroachdb.com/cockroach-v20.2.3.linux-amd64.tgz | tar xvz`

- `sudo mkdir -p /usr/local/lib/cockroach`

- `sudo cp -i cockroach-v20.2.3.linux-amd64/lib/libgeos.so /usr/local/lib/cockroach/`

- `sudo cp -i cockroach-v20.2.3.linux-amd64/lib/libgeos_c.so /usr/local/lib/cockroach/`

- `sudo mv cockroach-v20.2.3.linux-amd64/cockroach /usr/local/bin/`

- `sudo rm -rf cockroach-v20.2.3.linux-amd64`

#### Run it to create certificates

- `cockroach cert create-ca --certs-dir=certs --ca-key=my-safe-directory/ca.key`
- `cockroach cert create-client root --certs-dir=certs --ca-key=my-safe-directory/ca.key`

#### Save generated secrets in kube

- `kubectl create secret generic cockroachdb.client.root --from-file=certs`

#### Create the certificate and key pair for your CockroachDB nodes

```bash
cockroach cert create-node \
    localhost 127.0.0.1 cockroachdb-public \
    cockroachdb-public.default \
    cockroachdb-public.default.svc.cluster.local \
    '*.cockroachdb' '*.cockroachdb.default' \
    '*.cockroachdb.default.svc.cluster.local'\
    --certs-dir=certs --ca-key=my-safe-directory/ca.key
```

#### Save it

- `kubectl create secret generic cockroachdb.node --from-file=certs`

##              INSTALL
```bash
echo "[INFO] Will create a secure CockroachDB cluster"
kubectl create -f config/cockroachdb-statefulset.yaml
echo "[INFO] Will wait 5min for init"
sleep 300
echo "[INFO] Will run init command from cockroachdb-0 pod"
kubectl exec -it cockroachdb-0 -- /cockroach/cockroach init --certs-dir=/cockroach/cockroach-certs
echo "[INFO] Will create local sql client"
kubectl create -f config/client.yaml
```