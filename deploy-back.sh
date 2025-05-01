#!/bin/bash
set -e

echo "ondam 네임스페이스 생성 (이미 존재해도 무시)"
kubectl create namespace ondam 2>/dev/null || echo "이미 존재함"

echo "ondam-backend 배포"
kubectl apply -f k8s/backend-deployment.yml
kubectl apply -f k8s/backend-service.yml

echo "백엔드 배포 완료"
