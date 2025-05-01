# 🔧 온담 프로젝트 CI/CD 파이프라인

Vue 3 프론트엔드와 Spring Boot 백엔드가 독립적으로 구성된 `be14-4th-piveguyz-ondam` 프로젝트는  
**멀티 레포 기반 구조 + GitOps 기반 CD**를 결합하여,  
**개별 서비스의 빠른 배포와 안정성**을 동시에 확보하였습니다.

---

## 🧩 CI/CD 구성 개요

- **멀티 레포 구성**: `frontend/`, `backend/`를 Git Submodule로 관리
- **CI (Jenkins)**: 변경된 서비스만 빌드 및 Docker Hub에 이미지 푸시
- **CD (Argo CD)**: Git 상태와 Kubernetes 클러스터 자동 동기화
- **Docker**: Apple Silicon 대응 multi-arch 이미지 빌드
- **Kubernetes**: 무중단 배포를 위한 `rollout restart` 전략 적용

---

## 📁 프로젝트 구조

\`\`\`
be14-4th-piveguyz-ondam/
├── backend/
├── frontend/
├── k8s/
│ ├── ondam-back-_.yml
│ ├── ondam-front-_.yml
│ └── ingress.yml
├── argocd/
│ └── ondam-front-app.yml
├── build-back.sh
├── build-front.sh
├── deploy-back.sh
├── deploy-front.sh
├── deploy-all.sh
└── deploy-ingress.sh
\`\`\`

---

## 🛎️ 초기 수동 배포 → Jenkins 자동화 전환

### ✴️ 수동 배포 당시

- `build-*.sh`, `deploy-*.sh` 스크립트를 직접 실행
- 반복 작업이 많고, 실수 발생 확률 높음

\`\`\`bash
./build-front.sh
./deploy-front.sh
\`\`\`

### ✅ Jenkins 도입 후

- Webhook 기반 자동 트리거
- 변경된 서비스만 선택적으로 빌드/배포
- **무중단 배포 (`rollout restart`) 지원**
- `.yml` 수정까지 포함하여 **Argo CD에 반영 가능**

---

## ⚙️ Jenkins + Argo CD 파이프라인 흐름

### ✅ Jenkins (CI)

- GitHub Webhook 기반 트리거
- 디렉터리별 변경 감지 → `build-front.sh`, `build-back.sh` 실행
- Docker 이미지 빌드 및 Push
- `k8s/*.yml` 이미지 태그 업데이트 후 Git push

### ✅ Argo CD (CD)

- Git 상태 감지 → 클러스터 상태 자동 동기화
- UI로 배포 상태 모니터링 및 롤백 지원

---

## 🧱 멀티레포 구성의 장점

- **독립적인 빌드 및 배포 가능**
  - 프론트 변경 시 → `frontend`만 빌드/배포
  - 백엔드 변경 시 → `backend`만 빌드/배포
- **협업 효율 증가**
  - 팀 간 코드 충돌 최소화
- **서브모듈 구조 덕분에 전체 파이프라인은 메인 레포지토리에서 관리**

---

## 🚀 Argo CD를 통한 무중단 배포

- `main` 브랜치의 `k8s/*.yml`이 변경되면 Argo CD가 자동 감지
- `kubectl rollout restart` 명령과 함께 사용하면,  
  Pod 교체 과정에서 기존 트래픽은 유지되므로 **무중단 배포가 가능**

---

## 📄 Jenkins 파이프라인 코드

<details>
<summary>🔍 전체 파이프라인 보기</summary>

\`\`\`groovy

pipeline {

    agent any

    triggers {
        githubPush()
    }

    environment {
        BACK_IMAGE = 'morris235/ondam-backend:latest'
        FRONT_IMAGE = 'morris235/ondam-frontend:latest'
    }

    stages {
        stage('SCM Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/Pive-Guyz/be14-4th-piveguyz-ondam.git'
                    ]],
                    extensions: [[$class: 'SubmoduleOption', recursiveSubmodules: true]]
                ])
            }
        }

        stage('Detect Changes') {
            steps {
                script {
                    def backendChanged = sh(script: '''git diff --submodule=log HEAD^ HEAD | grep 'Submodule backend' > /dev/null''', returnStatus: true) == 0
                    def frontendChanged = sh(script: '''git diff --submodule=log HEAD^ HEAD | grep 'Submodule frontend' > /dev/null''', returnStatus: true) == 0

                    env.BACKEND_CHANGED = backendChanged.toString()
                    env.FRONTEND_CHANGED = frontendChanged.toString()

                    echo "🔍 BACKEND_CHANGED = ${env.BACKEND_CHANGED}"
                    echo "🔍 FRONTEND_CHANGED = ${env.FRONTEND_CHANGED}"
                }
            }
        }

        stage('Update Submodules') {
            when {
                expression { env.BACKEND_CHANGED == 'true' || env.FRONTEND_CHANGED == 'true' }
            }
            steps {
                sh '''
                    git submodule update --init --recursive
                    chmod +x backend/ondam-backend/gradlew
                '''
            }
        }

        stage('Inject application.yml for Test') {
            when {
                expression { env.BACKEND_CHANGED == 'true' }
            }
            steps {
                withCredentials([file(credentialsId: 'app-yml-ci', variable: 'APP_YML_CI')]) {
                    sh '''
                        mkdir -p backend/ondam-backend/src/main/resources
                        chmod -R u+w backend/ondam-backend/src/main/resources
                        cp "$APP_YML_CI" backend/ondam-backend/src/main/resources/application.yml
                    '''
                }
            }
        }

        stage('Backend Build') {
            when {
                expression { env.BACKEND_CHANGED == 'true' }
            }
            steps {
                dir('backend/ondam-backend') {
                    sh './gradlew clean build -x test'
                }
            }
        }

        stage('Frontend Build') {
            when {
                expression { env.FRONTEND_CHANGED == 'true' }
            }
            steps {
                dir('frontend') {
                    sh '''
                        rm -rf dist node_modules
                        npm install
                        npm run build
                    '''
                }
            }
        }

        stage('Inject application.yml for Docker Build') {
            when {
                expression { env.BACKEND_CHANGED == 'true' }
            }
            steps {
                withCredentials([file(credentialsId: 'app-yml-file', variable: 'APP_YML_DEPLOY')]) {
                    sh '''
                        mkdir -p backend/ondam-backend/src/main/resources
                        chmod -R u+w backend/ondam-backend/src/main/resources
                        cp "$APP_YML_DEPLOY" backend/ondam-backend/src/main/resources/application.yml
                    '''
                }
            }
        }

        stage('Docker Login') {
            when {
                expression { env.BACKEND_CHANGED == 'true' || env.FRONTEND_CHANGED == 'true' }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'DOCKERHUB_PASSWORD', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                }
            }
        }

        stage('Docker Build & Push') {
            parallel {
                stage('Backend Docker') {
                    when {
                        expression { env.BACKEND_CHANGED == 'true' }
                    }
                    steps {
                        dir('backend/ondam-backend') {
                            sh '''
                                docker build -t $BACK_IMAGE .
                                docker push $BACK_IMAGE
                            '''
                        }
                    }
                }
                stage('Frontend Docker') {
                    when {
                        expression { env.FRONTEND_CHANGED == 'true' }
                    }
                    steps {
                        dir('frontend') {
                            sh '''
                                docker build -t $FRONT_IMAGE .
                                docker push $FRONT_IMAGE
                            '''
                        }
                    }
                }
            }
        }

        stage('Kubernetes Backend Deploy') {
            when {
                expression { env.BACKEND_CHANGED == 'true' }
            }
            steps {
                sh '''
                    kubectl create namespace ondam 2>/dev/null || echo "Namespace already exists"
                    kubectl apply -f k8s/ondam-back-dep.yml
                    kubectl apply -f k8s/ondam-back-ser.yml
                    kubectl rollout restart deployment ondam-back-dep -n ondam
                '''
            }
        }

        stage('Kubernetes Frontend Deploy') {
            when {
                expression { env.FRONTEND_CHANGED == 'true' }
            }
            steps {
                sh '''
                    kubectl create namespace ondam 2>/dev/null || echo "Namespace already exists"
                    kubectl apply -f k8s/ondam-front-dep.yml
                    kubectl apply -f k8s/ondam-front-ser.yml
                    kubectl rollout restart deployment ondam-front-dep -n ondam
                '''
            }
        }
    }

}

\`\`\`

</details>

---

## ✅ 실행 결과 요약

1. GitHub → `main` 브랜치에 push 발생
2. Jenkins Webhook 트리거 → 파이프라인 실행
3. 변경된 서비스만 빌드 및 Docker 이미지 생성
4. DockerHub 푸시 + `k8s/*.yml` 수정 및 Git push
5. Argo CD가 자동 감지 → 클러스터 동기화
6. **frontend/back 각각의 변경에 대해 독립적, 무중단 배포 실행**

---

## 🌿 브랜치 전략 및 배포 흐름

온담 프로젝트는 다음과 같은 **단계적 브랜치 전략**을 기반으로 안정적인 배포 흐름을 구축했습니다.

### 🗂 브랜치 구조

- `develop`: 기능 개발 및 통합 테스트 진행
- `deploy/dev-snapshot`: 배포 직전 단계의 검증 브랜치
- `main`: 실제 운영용 코드가 머지되는 최종 브랜치

### 🔗 멀티레포 연동 방식

- `frontend/`, `backend/`는 각각 별도의 독립 레포로 운영됨
- 메인 레포인 `be14-4th-piveguyz-ondam`에는 두 레포가 Git Submodule로 연결되어 있음
- 브랜치 전략은 **서브모듈에서도 동일하게 적용**되며,
  - `develop` → `deploy/dev-snapshot` → 메인 레포 반영 → Argo CD 배포 흐름으로 이어짐

### ✅ 흐름 요약

1. 기능은 각 서비스 레포의 `develop` 브랜치에서 개발
2. 기능 완료 시 `deploy/dev-snapshot`로 머지하여 배포 대상 확정
3. 메인 레포지토리의 Submodule을 업데이트하여 `main` 브랜치로 커밋
4. Jenkins → Argo CD로 이어지는 자동화 배포 트리거

이 방식은 **기능 개발, 검증, 배포를 명확하게 분리**하고,  
각 서비스의 변경을 독립적으로 배포 가능하게 만들어줍니다.
