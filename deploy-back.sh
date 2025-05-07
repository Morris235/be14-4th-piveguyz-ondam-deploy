#!/bin/bash
set -e

echo "🔧 ondam 네임스페이스 생성 (이미 존재해도 무시)"
kubectl create namespace ondam 2>/dev/null || echo "→ 이미 존재함"

echo "🧹 오래된 백엔드 Deployment 제거"
kubectl delete deployment ondam-backend -n ondam 2>/dev/null || echo "→ 제거할 백엔드 Deployment 없음"

echo "🧹 단독 실행된 오래된 백엔드 Pod 제거"
kubectl get pods -n ondam -o name | grep ondam-backend- | grep -v ondam-back-dep | xargs -r kubectl delete -n ondam

echo "🧯 nodePort 30083을 점유 중인 서비스 확인 및 삭제"
SERVICE_INFO=$(kubectl get svc -A -o jsonpath='{range .items[?(@.spec.ports[0].nodePort==30083)]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}')
if [ -n "$SERVICE_INFO" ]; then
  while read -r namespace name; do
    echo "→ 삭제: $namespace/$name"
    kubectl delete svc "$name" -n "$namespace"
  done <<< "$SERVICE_INFO"
else
  echo "→ 30083 포트를 사용하는 서비스 없음"
fi

echo "🧽 기존 ondam-back-ser 서비스 제거 (중복 방지)"
kubectl delete svc ondam-back-ser -n ondam 2>/dev/null || echo "→ 삭제할 기존 서비스 없음"

echo "🚀 ondam-backend Deployment 및 Service 배포"
kubectl apply -f k8s/ondam-back-dep.yml
kubectl apply -f k8s/ondam-back-ser.yml

# 수동배포용
echo "♻️ 변경된 이미지를 반영하기 위해 rollout restart 실행"
kubectl rollout restart deployment ondam-back-dep -n ondam

echo "✅ 백엔드 배포 및 롤아웃 완료"
