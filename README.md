# Setup

### Setup AWS Infrastructure
* terraform init
  ```
  export AWS_ACCESS_KEY="" \
    AWS_SECRET_KEY="" \
    AWS_REGION="" \
    TF_VAR_aws_access_key="" \
    TF_VAR_aws_secret_key="" \
    TF_VAR_aws_region="" \
    TF_VAR_aws_account_id="" \
    TF_VAR_db_username="" \
    TF_VAR_db_password=""
  env |egrep "^AWS*|^TF_VAR*"
  ```
  ```
  terraform init
  ```

<br>

### Setup EKS Secret for K8S
* frontend secret
  ```
  cat << EOF > ./k8s/manifest/dev/frontend_secret.yml
  apiVersion: v1
  kind: Secret
  metadata:
    name: frontend-secret
    namespace: hoge
  type: Opaque
  data:
    NEXT_PUBLIC_API_HOST: dGVzdA==

  EOF
  ```

* backend secret
  ```
  cat << EOF > ./k8s/manifest/dev/backend_secret.yml
  apiVersion: v1
  kind: Secret
  metadata:
    name: backend-secret
    namespace: hoge
  type: Opaque
  data:
    DB_NAME: dGVzdA==
    DB_USER: dGVzdA==
    DB_PASSWORD: dGVzdA==
    DB_HOST: dGVzdA==
    REDIS_HOST: dGVzdA==
    DOMAIN: dGVzdA==

  EOF
  ```