# Run-sheet: build the whole project in one day

Do the parts in order. Every part ends with a **Check**; don't move on until it passes.
Rough timings: 7–9 hours in total, with about 5–6 hours of EKS running.

> **Cost warning:** EKS charges by the hour from Part C until you finish Part I.
> Do Part I (teardown) the same day, even if you don't finish everything else.

---

## Part A: Setup (45 min)

### A1. Install the tools

**Mac (Homebrew):**
```bash
brew install git awscli terraform kubectl helm kind
brew install --cask docker   # then open Docker Desktop once
```

**Windows:** install WSL2 with Ubuntu, plus Docker Desktop with WSL integration, then run the Linux steps inside Ubuntu.

**Linux / WSL (Ubuntu):** install Docker, then follow the official install pages for:
the AWS CLI v2, Terraform (1.10 or newer), kubectl, Helm 3 and kind.

Check:
```bash
git --version && aws --version && terraform version && kubectl version --client && helm version && kind version && docker ps
```

### A2. AWS account safety (do this before anything else)
1. Turn on MFA for the root user.
2. Create an admin user for daily work (IAM Identity Center, or an IAM user with MFA). Don't use root.
3. **Billing → Budgets → Create budget**: monthly cost budget of **$20**, with email alerts at 50% and 100%.
4. Log in on your machine:
   ```bash
   aws configure sso      # or: aws configure  (IAM user keys stay on your laptop only, never in Git)
   aws sts get-caller-identity
   ```
5. Use the region **eu-north-1 (Stockholm)** for everything.

### A3. Put the code on GitHub
1. On GitHub, create a **public** repository called `eks-gitops-platform` (public so Argo CD can read it without credentials, and recruiters can see it).
2. Unzip this project, then:
   ```bash
   cd eks-gitops-platform
   git init -b main
   git add .
   git commit -m "feat: initial project structure"
   git remote add origin https://github.com/<your-user>/eks-gitops-platform.git
   git push -u origin main
   ```

**Check:** you can see the files on GitHub.

---

## Part B: Run it locally, free (1–1.5 h)

### B1. Docker Compose
```bash
docker compose up --build
```
Open http://localhost:8080 and create a few orders. They should flip from **new** to **processed** within about 5 seconds (that's the worker).
Also try http://localhost:8000/docs (API docs) and http://localhost:8000/metrics.

Stop it with `Ctrl+C`, then `docker compose down`.

### B2. Local Kubernetes with kind and Helm
```bash
./scripts/local-up.sh
kubectl port-forward -n shop svc/frontend 8080:80
```
Open http://localhost:8080 again. Then explore:
```bash
kubectl get pods -n shop
kubectl describe deploy api -n shop
kubectl logs -n shop deploy/worker
```
Clean up: `./scripts/local-down.sh`

**Check:** all pods Running and 1/1 Ready; the app works through the port-forward.

Commit any notes: `git commit -am "docs: local testing notes" && git push`

---

## Part C: AWS infrastructure with Terraform (45 min, about 20 of it waiting)

### C1. State bucket (once)
```bash
cd infra/terraform/bootstrap
terraform init
terraform apply          # type "yes"
cd ../../..
```

### C2. Fill in your account ID and repo name
```bash
./scripts/configure.sh <your-user>/eks-gitops-platform
git diff                 # check what changed
git commit -am "chore: configure account and repo"
git push
```

### C3. VPC, EKS, ECR, secret, IAM roles
```bash
cd infra/terraform/envs/dev
terraform init
terraform plan           # read it: about 60-70 resources to add
terraform apply          # type "yes"; takes about 15-20 minutes
```
If it says the GitHub OIDC provider already exists, add `create_github_oidc_provider = false` to `terraform.tfvars` and apply again.

Keep the outputs, you'll need them:
```bash
terraform output
```

### C4. Connect kubectl
```bash
$(terraform output -raw configure_kubectl)
kubectl get nodes
cd ../../../..
```
(Back at the repo root: run `git rev-parse --show-toplevel` if unsure.)

**Check:** `kubectl get nodes` shows 2 nodes in `Ready` state.

---

## Part D: CI pipeline (30 min)

### D1. Tell GitHub which AWS role to use
GitHub repo → **Settings → Secrets and variables → Actions → Variables → New repository variable**
- Name: `AWS_ROLE_ARN`
- Value: the `github_actions_role_arn` output from Terraform

Optional: to turn on SonarQube Cloud, create a free project at sonarcloud.io, add the `SONAR_TOKEN` **secret**, and fill in `sonar-project.properties`. The pipeline skips that step until you do.

### D2. Run the pipeline
GitHub → **Actions → ci → Run workflow** (on `main`).

Watch the jobs: secret scan → unit tests → build, Trivy scan and push (×3) → update image tag.

```bash
git pull   # brings down the bot's commit that changed helm/shop/values-eks.yaml
```

**Check:** the run is green; the ECR console shows images in `shop-api`, `shop-worker` and `shop-frontend`; `values-eks.yaml` now has a commit SHA as the tag.

If Trivy fails on a vulnerability: read which package it is. Usually rebuilding later (newer base image) fixes it; this is the scan working, not a bug.

---

## Part E: Platform tools and GitOps (40 min)

### E1. Install everything
```bash
./scripts/install-platform.sh
```
It prints the Grafana and Argo CD passwords. Save them somewhere private (not in Git).

### E2. Check the app
```bash
kubectl get applications -n argocd                       # shop: Synced, Healthy
kubectl get externalsecret -n shop                       # shop-db: SecretSynced
kubectl get pods -n shop
kubectl port-forward -n shop svc/frontend 8080:80        # http://localhost:8080
```

Open Argo CD:
```bash
kubectl port-forward -n argocd svc/argocd-server 8081:443   # https://localhost:8081, user admin
```

### E3. Prove GitOps works
1. **Change through Git:** in `helm/shop/values.yaml` set `api.replicas: 3`, then commit and push. Within about 3 minutes Argo CD rolls out a third API pod (or press **Refresh** in the UI).
2. **Self-healing:** run `kubectl scale deploy api -n shop --replicas=1` and watch Argo CD put it back to 3.

**Check:** the app works; the database password came from AWS Secrets Manager (`kubectl get secret shop-db -n shop` exists and was created by the ExternalSecret); Git changes deploy on their own.

---

## Part F: Monitoring and SLO (30 min)

Terminal 1, steady traffic:
```bash
./scripts/load.sh
```

Terminal 2, Grafana:
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80   # http://localhost:3000
```
- **Dashboards → Shop API**: requests per second, error ratio, p95 latency, restarts and logs.
- **Explore → Loki**: try `{namespace="shop", app="api"}` and `{namespace="shop", app="worker"} |= "processed"`.

Terminal 3, Prometheus alerts:
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090   # http://localhost:9090/alerts
```
Find `ShopApiErrorBudgetFastBurn`; it should be green (inactive).

**Check:** the dashboard shows live traffic and logs.

---

## Part G: Break it on purpose and write the RCA (45 min)

Keep `load.sh` running. **Write down the time of every step**; you'll need it for the RCA.

1. Make the bad change in `helm/shop/values-eks.yaml`, adding under the existing keys:
   ```yaml
   api:
     replicas: 3
     failureRate: "0.3"
   ```
   Commit with a realistic message, e.g. `git commit -am "chore: tune api settings"`, then push.
2. Argo CD deploys it. Watch the error ratio climb past 7.2% on the dashboard.
3. After a few minutes the alert turns **Pending**, then **Firing** in Prometheus. Screenshot it.
4. Investigate like it's real:
   - Grafana: when did errors start?
   - Loki: `{namespace="shop", app="api"} |= " 500"`
   - Argo CD → shop → **History and rollback**: which commit was deployed just before?
5. Fix through Git:
   ```bash
   git revert HEAD --no-edit && git push
   ```
6. Watch the error ratio drop and the alert resolve.
7. Fill in `docs/rca-001.md` with your real times, numbers and screenshots, then commit it.

Optional second incident: set `api.resources.limits.memory: 20Mi` to see `OOMKilled` and restarts, then revert.

---

## Part H: Screenshots and README (30 min)

Save these in `docs/screenshots/`:
1. The green GitHub Actions run
2. The ECR repositories with images
3. The Argo CD application tree (Synced, Healthy)
4. The Grafana dashboard during the incident
5. The alert firing in Prometheus
6. The Loki query showing the 500 errors

Add them to the README, then fill in the **Problems I hit** section with what actually went wrong for you and how you fixed it. Commit and push.

---

## Part I: Teardown (30 min). Do not skip this.

```bash
./scripts/cleanup-k8s.sh
cd infra/terraform/envs/dev
terraform destroy        # type "yes"; about 15 minutes
```

Then check the AWS console (region eu-north-1) that nothing is left:
- **EC2 → Load Balancers**: empty
- **EC2 → Volumes**: no "available" volumes from the cluster
- **VPC → NAT gateways**: none (or "Deleted")
- **EC2 → Elastic IPs**: none left over

The state bucket costs a few cents a month. Keep it if you want to rebuild later, or remove it:
```bash
cd ../../bootstrap && terraform destroy
```

Tomorrow: **Billing → Bills** to confirm what you were charged.

---

## When you're done
- On your CV, change "Personal project (in progress, 2026)" to "Personal project, 2026", put the bullets in the past tense, and remove anything you didn't build.
- Pin the repository on your GitHub profile.
- Practise the interview questions in the build-plan doc out loud.
