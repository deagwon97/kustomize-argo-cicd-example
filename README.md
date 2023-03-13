# 1. Intro

 기존에 Jenkins를 통해서 CI/CD를 구축하고 사용하고 있었습니다. 하지만 몇가지 이유로 Jenkins를 버리고 Argo Project의 도구들을 활용하여 새로운 CI/CD를 구축했습니다. 자세한 소스코드는 아래 github 에 올려두었으니 참고바랍니다.

- [https://github.com/deagwon97/kustomize-argo-cicd-example](https://github.com/deagwon97/kustomize-argo-cicd-example)

## 1) Jenkins를 떠나는 이유

- Jenkins의 구린 UI
    - 구려도 너무 구립니다.
- 잦은 플러그인 버전 업그레이드
    - Jenkins의 장점은 다양한 플러그인입니다. 하지만 이는 단점이기도 합니다. 플러그인이 다양한 만큼 변경도 잦습니다. 한 번 세팅하고 나서도 빈번하게 플러그인들을 업그레이드 해야합니다.
- GUI를 통한 설정
    - GUI를 통서 설정할 경우, 설정 사항을 문서화하는 것이 어렵습니다. 나중에 다른 프로젝트를 위해서 설정을 바꾼다거나 새롭게 구성할 때, 같은 고생을 반복하면서 이건 정말 고쳐야겠다고 생각했습니다.
    - 사실 위 문제는 Jenkins cli를 통해서 해결할 수 있스니다. 하지만, 플러그인 설치 및 관리가 쉽지않고 클러스터에서 프로비저닝 후 추가 스크립트를 실행해야 합니다. 저는 이러한 작업을 최소화하고, `kubectl apply -k .` 과 같은 커맨드로 프로비저닝 작업을 최소화 하고 싶었습니다.


<div align="center">
    <img  width="50%" src="https://velog.velcdn.com/images/curiosity806/post/27e4a1f6-bd0d-4669-8cf8-30ff6022ff5d/image.png"/>
</div>


## 2) 다른 후보 - Tekton & GoCD

### a) Tekton

 Tekton은 CI/CD 파이프라인을 빠르게 구축하기 위한 프레임워크를 제공하는 Cloud-native 오픈소스 프로젝트입니다. 클라우드 네이티브 프로젝트이기 때문에 kubernetes의 CustomResource로 정의되어 있습니다. 또한 모듈화가 잘 되어 있어 재사용이 용이하다고 합니다. 직관적이고 설치가 간단하여 바로 도입했습니다. 하지만, 대쉬보드에 대한 인증기능이 존재하지 않다는 치명적인 단점이 있었습니다. 대쉬보드에 DNS를 붙이고 모니터링하고 싶었는데, 이를 위해서 인증기능을 직접 구현하는 것은 불필요하다고 판단하고, 중간에 도입을 포기했습니다.

<div align="center">
    <img  width="50%" src="https://velog.velcdn.com/images/curiosity806/post/e6e025ad-df6f-4ff7-b92d-557be894fdd3/image.png"/>
</div>


### b) GoCD

 설정이 쉽고, 대쉬보드 디자인이 깔끔합니다. 또한 제가 원하는 수준의 인증 및 권한관리 기능을 지원합니다. GoCD는 Cloude Native 하지는 않지만, agent로 kubernetes의 pod을 사용할 수 있어서, 설정을 kustomization 명세에 담을 수 있었습니다. (secret, pipline 설정 등)

하지만 아래 문제를 마주했고, 향후에도 비슷한 문제가 반복될 수 있다고 판단해 도입을 포기했습니다.

> GoCD를 Kubernetes에서 사용하기 위해서는 작업을 수행하는 작업자가 gocd-agent 이미지 위에서 동작해야 합니다. 저는 이미지를 빌드하는 Kaniko 이미지와 GoCD-Agent 이미지를 합쳐서 새로운 이미지를 만들었습니다. 이렇게 새로 만든 이미지로 Job을 수행했더니 gocd-controller 가 gocd-agent의 상태를 제대로 추적하지 못하는 문제가 생겼습니다.
> 

<div align="center">
    <img  width="50%" src="https://velog.velcdn.com/images/curiosity806/post/fbd9a17f-1e35-4213-96a8-24707c649dce/image.png"/>
</div>



# 2. Argo Project


<div align="center">
    <img  width="50%" src="https://velog.velcdn.com/images/curiosity806/post/f1be2849-c340-4e53-af8c-13da0e1f3f21/image.png"/>
</div>


 ArgoCD는 클라우드 네티브합니다. 대부분의 설정과 Job이 kuberntes CRD를 생성하여 관리할 수 있습니다. 더욱이 제가 원하는 수준의 대쉬보드 인증 및 권한 관리 기능을 제공하고, 깔끔한 UI까지 갖췄습니다.  정말이지 완벽합니다. 하지만, 과하다고 판단했습니다. Argo는 CD, CI, Event, Rollout 등 개별앱을 설치해서 사용해야 하고, 각 앱들이 지원하는 기능은 제가 사용하지 않을 만한 기능이 너무 많아서 도입을 망설였습니다.

 하지만, 결과적으로 위에서 이야기 했던 문제들을 마주 했고, 설정이 어렵더라도, Argo Project를 사용해서 CI/CD 프로세스를 도입하기로 결정했습니다.

## 1) Argo Workflows & Argo Events

 Argo Workflows는 CI  Workflow를 관리하는 도구입니다. 저는 Workflow로 build와 deploy라는 step을 만들었고, Argo Events를 통해서 Github에서 Webhook이 들어오면 이 Workflow가 실행되도록 구현했습니다. 

 참고로, Argo Project 문서에서는 Argo Workflows와 Argo Events를 다른 namespace로 두고 사용하지만, 필자는 이 두 도구가 관련되어있고, 굳이 분리할 필요가 없다고 판단하여 `argoci` 라는 이름의 namespapce에 함께 생성했습니다.

### a. Argo Workflows

 제가 만든 argo workflow는 간단하게 2가지 스텝을 가집니다. build step을 통해서 app의 컨테이너 이미지를 빌드하고, deploy step에서 kubectl 커맨드로 앱을 배포합니다. argo rollout을 사용할 수도 있지만, kubectl 커맨드를 사용하는 것만으로도 충분하다고 판단했습니다.

- Build Step
    - image: ****csanchez/kaniko****
    - 용도
        1. Github에서 소스코드를 Pull
        2. 새로운 컨테이너 이미지를 빌드
        3. harbor registry에 이미지를 Push
- Deploy Step
    - image: ****bitnami/kubectl****
    - 용도
        - `kubectl rollout restart deployment <name> -n <namespace>` 커맨드를 통해 앱 배포

### b. Argo Events

- Event-Source
    - 외부 소스로부터 들어오는 이벤트를 정의
    - AWS SNS, SQS, GCP PubSub, Webhooks 등을 지원
    - 외부 이벤트가 들어오면 클라우드 이벤트로 변환하여 Event Bus로 전달
- Event Bus
    - event source와 event sensor를 연결하는 역할을 수행한다.
    - 마치 Transport layer와 같이 동작한다.
- Event-Sensor
    - event bus에서 어떤 이벤트가 들어왔을 때(Event dependency), 어떤 동작을 수행할 지(triggers) 정의

### c. Detail

 Argo cd와 다르게 Argo Workflows와 Argo Events를 하나로 묶기위해서는 추가적인 설정이 필요합니다. 

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: argo-ci
generatorOptions:
  disableNameSuffixHash: true
resources:
  # argo workflows
  - namespace.yaml # namespace 생성
  - https://github.com/argoproj/argo-workflows/releases/download/v3.4.5/install.yaml # argo workflows 설치
  - workflow-rbac.yaml # argo workflows에 workflow pods을 조회, 수정, 생성, 삭제하는 권한 부여 (dashboard 조회용)
  - rollout-rbac.yaml # argo workflows에 외부 deployment를 rollout restart 하기 위한 권한 부여
  # argo events
  - https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install.yaml
  - https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install-validating-webhook.yaml
  - event-source.yaml # github webhook을 감지하여 event bus로 전송
  - event-bus.yaml # event source의 event를 event sensor로 전송
  - event-sensor.yaml # event-sensor와 workflow를 모두 포함함. event bus에서 event가 전달되면, workflow를 실행.
  - event-rbac.yaml # event sensor가 workflow를 생성할 수 있는 권한 부여
  # ingress
  - ingress.yaml # argo ci 의 대쉬보드, webhook listener를 외부로 배포.
patchesStrategicMerge:
  - argo-patch.yaml
secretGenerator:
  - name: git-secret
    envs:
    - kaniko/git-secret
  - name: git-ssh
    files:
      - .ssh/id_rsa
  - name: git-known-hosts
    files:
      - .ssh/known_hosts
configMapGenerator:
  - name: harbor-config
    files:
      - kaniko/config.json
  - name: rollout-kubeconfig
    files:
      - rollout/config
```

이렇게 만들어진 argoci 또한 대쉬보드로 접속할 수 있습니다. github에서 push가 들어오면 자동으로 build, deploy 되며, 중간 과정에서 pod들의 로그를 실시간으로 확인할 수 있습니다.


<div align="center">
    <img  width="50%" src="https://velog.velcdn.com/images/curiosity806/post/bdd06483-7e47-484a-b7d5-0b8b90f2330d/image.png"/>
</div>

## 2) ArgoCD

 Kubernetes의 형상을 유지하는 도구입니다. Kustomization 파일을 Polling 하며, 변화가 감지되면 이를 클러스터에 반영합니다. 앱의 수정사항을 반영하여 배포하는 것이 아닌, Kubernetes의 Service, Pod 등의 형상을 관찰하여 Kustomization 파일과 항상 동일한 상태를 유지하도록 관리하는 도구입니다. 

 이전에 Jenkins로 구축했던 CI/CD는 소스코드의 변경사항을 배포하는 기능만 있었지 kubernetes 리소스의 형상을 관리하지는 않았습니다. 하지만, ArogoCD 문서를 충분히 읽은 후, 형상 또한 코드로 관리하면서 지속적으로 동일한 상태를 유지할 필요가 있다고 판단하여 추가로 도입했습니다.

### a. Detail

설정 방법은 간단합니다.  아래와 같이 kustomization 파일을 작성한 후,

```yaml
#kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: argocd
generatorOptions:
  disableNameSuffixHash: true # traefik의 Ingress Router가 argocd service를 식별하기 위함.
resources:
  - namespace.yaml # namespace 생성
  - https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  - ingress.yaml # dashboard를 외부에 배포하기위한 ingress 및 certificate, issuer 설정
  - repository.yaml # Argocd의 Application에서 사용되는 github repository를 생성하는 yaml
  - application.yaml # Argocd의 Application을 생성하는 yaml
patchesStrategicMerge:
  - argocd-cmd-params-cm-patch.yml # argocd 생성 파라미터에서 server.insecure: "true" 으로 설정
```

 argocd 폴더에서  `kustomization applyo -k .`  커맨드를 실행하면, 설치부터 설정까지 한번에 완성됩니다!

이렇게 생성된 argocd 앱을 대쉬보드로 확인할 수 있습니다. get-key.sh 스크립트를 실행하여 얻은 password로 로그인할 수 있습니다. (기본 id는 admin입니다.)


<div align="center">
    <img  width="90%" src="https://velog.velcdn.com/images/curiosity806/post/38846afc-ef29-460d-ae73-12fc924cb559/image.png"/>
</div>


이제 정말 만족스러운 CI/CD 프로세스가 구축됐습니다. 모든 설정은 소스코드로 관리하면서 쿠버네티스 네이티브한 프로세스가 만들어졌습니다. 조금 더 완성도를 높인다면 다음과 같은 작업을 추가할 수 있겠지만, 지금도 충분하다고 생각합니다. 향후 필요하다고 판단된다면 적용해 볼 생각입니다.

- argocd, argoci kustomization 파일도 argocd 에 포함하여 배포
- build된 이미지를 테스트하는 step 추가
- workflow template를 사용하여 설정 파일 재사용성 확대

## Reference

- [https://argoproj.github.io/argo-workflows/quick-start/](https://argoproj.github.io/argo-workflows/quick-start/)