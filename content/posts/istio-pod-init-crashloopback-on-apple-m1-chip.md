---
author: minwoo.kim
categories:
  - Mac
  - Istio
date: 2022-05-28T03:30:00Z
tags:
  - Kubernetes
  - k8s
  - Istio
title: 'Istio Pod Init:CrashLoopBackOff 에러 (Apple M1 Chip, ARM CPU)'
cover:
  image: '/assets/img/istio.png'
  alt: 'Istio'
  relative: false
showToc: true
---

# Istio Pod Init:CrashLoopBackOff

**환경:** Apple M1 Chip / M1과 같은 **ARM 기반 CPU**

Istio 테스트를 하기 위해 로컬 환경인 docker-desktop이나 minikube 등을 이용하여 Istio sidecar injection을 하면 에러가 발생하는 것을 확인할 수 있습니다.

## 에러 발생 시키기

**주의:** {{< newtabref href="https://istio.io/latest/docs/setup/install/istioctl/" title="Istio 공식 문서" >}}를 보고 Istio를 설치했다고 가정하고 진행합니다.

### Nginx Deployment 적용

```bash
curl -Ls https://k8s.io/examples/application/deployment.yaml | istioctl kube-inject -f - | kubectl apply -f -
```

### 포드(pod) 목록 및 상태 확인

```
kubectl get pods -l app=nginx
```

```plaintext
NAME                               READY   STATUS                  RESTARTS        AGE
nginx-deployment-fc9fcd7c7-98wzz   0/2     Init:CrashLoopBackOff   5 (2m15s ago)   5m12s
nginx-deployment-fc9fcd7c7-d5dkh   0/2     Init:CrashLoopBackOff   5 (2m9s ago)    5m12s
```

포드가 다시 살아나지 못하고 CrashLoopBackOff 상태인 것을 확인할 수 있습니다.

### nginx pod의 istio-init container 로그 확인

```bash
# 직접 pod 이름으로 로그 확인
kubectl logs nginx-deployment-fc9fcd7c7-98wzz

# pod 이름을 사용하지 않고 로그 확인
kubectl logs $(kubectl get po -l app=nginx | tail -n +2 | head -n 1 | cut -d ' ' -f 1) istio-init
```

```plaintext
...

2022-05-28T14:49:12.861202Z	info	Running command: iptables-restore --noflush /tmp/iptables-rules-1653749352860534672.txt2794510670
2022-05-28T14:49:12.883609Z	error	Command error output: xtables parameter problem: iptables-restore: unable to initialize table 'nat'

Error occurred at line: 1
Try `iptables-restore -h' or 'iptables-restore --help' for more information.
2022-05-28T14:49:12.883973Z	error	Failed to execute: iptables-restore --noflush /tmp/iptables-rules-1653749352860534672.txt2794510670, exit status 2
```

포드의 로그를 확인해본 결과 위와 같이 iptables 관련 에러가 나는 것을 확인할 수 있습니다.

## 해결 방법

m1, 즉 arm 기반 CPU는 기본으로 제공되는 것과 다른 docker image를 사용해야합니다.

{{< newtabref href="https://github.com/resf/istio" title="해당 GitHub 링크" >}}를 참고하여 아래와 같이 설치합니다.

### 새로운 Istio Operator 설치

```bash
# nginx deployment 생성했다면 제거
kubectl delete deploy nginx-deployment

# 기존 istio 제거
kubectl delete ns istio-system istio-operator

# tag에는 현재 istioctl 버전을 입력
istioctl operator init --hub=ghcr.io/resf/istio --tag=1.13.4
```

### 새로운 hub에서 Istio 설치

아래와 같이 hub를 `ghcr.io/resf/istio` 로 지정하여 apply 합니다.  
profile은 알맞게 설정하여 사용하시면 됩니다.

```bash
# istio-system namespace가 없는 경우에만 생성
kubectl create ns istio-system

# istio install (istio-ingressgateway, istiod 등)
kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  hub: ghcr.io/resf/istio
  profile: default
EOF
```

위와 같이 하고 나서 nginx를 다시 띄워 확인해봅니다.

### Nginx Deployment 새로 적용

```bash
curl -Ls https://k8s.io/examples/application/deployment.yaml | istioctl kube-inject -f - | kubectl apply -f -
```

```bash
kubectl get pods -l app=nginx
```

### 새로운 포드(pod) 목록 및 상태 확인

```plaintext
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-668b6747c6-cspxr   2/2     Running   0          8m57s
nginx-deployment-668b6747c6-jlsxz   2/2     Running   0          8m57s
```

위와 같이 이제 pod들이 잘 뜨는 것을 확인할 수 있습니다.

감사합니다.

## 참고

- {{< newtabref href="https://github.com/resf/istio" title="Istio OCI Images (linux/arm64, linux/amd64)" >}}
- {{< newtabref href="https://github.com/istio/istio/issues/36762" title="on mac m1 : error Command error output: xtables parameter problem: iptables-restore: unable to initialize table 'nat' #36762" >}}
