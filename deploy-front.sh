#!/bin/bash
set -e

echo "🔧 ondam 네임스페이스 생성 (이미 존재해도 무시)"
kubectl create namespace ondam 2>/dev/null || echo "→ 이미 존재함"

echo "🧹 오래된 프론트엔드 Deployment 제거"
kubectl delete deployment ondam-frontend -n ondam 2>/dev/null || echo "→ 제거할 프론트엔드 Deployment 없음"

echo "🧹 단독 실행된 오래된 프론트엔드 Pod 제거"
kubectl get pods -n ondam -o name | grep ondam-frontend- | grep -v ondam-front-dep | xargs -r kubectl delete -n ondam

echo "🧯 nodePort 30080을 점유 중인 서비스 확인 및 삭제"
SERVICE_INFO=$(kubectl get svc -A -o jsonpath='{range .items[?(@.spec.ports[0].nodePort==30080)]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}')
if [ -n "$SERVICE_INFO" ]; then
  while read -r namespace name; do
    echo "→ 삭제: $namespace/$name"
    kubectl delete svc "$name" -n "$namespace"
  done <<< "$SERVICE_INFO"
else
  echo "→ 30080 포트를 사용하는 서비스 없음"
fi

echo "🧽 기존 ondam-front-ser 서비스 제거 (중복 방지)"
kubectl delete svc ondam-front-ser -n ondam 2>/dev/null || echo "→ 삭제할 기존 서비스 없음"

echo "🚀 ondam-frontend Deployment 및 Service 배포"
kubectl apply -f k8s/ondam-front-dep.yml
kubectl apply -f k8s/ondam-front-ser.yml

echo "✅ 프론트엔드 배포 완료"
