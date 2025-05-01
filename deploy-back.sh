#!/bin/bash
set -e

echo "ondam 네임스페이스 생성 (이미 존재해도 무시)"
kubectl create namespace ondam 2>/dev/null || echo "이미 존재함"

echo "ondam-backend 배포"
kubectl apply -f k8s/ondam-back-dep.yml
kubectl apply -f k8s/ondam-back-ser.yml

echo "백엔드 배포 완료"
