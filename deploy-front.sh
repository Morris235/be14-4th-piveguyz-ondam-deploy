#!/bin/bash
set -e

echo "ondam-frontend 배포"
kubectl apply -f k8s/frontend-deployment.yml
kubectl apply -f k8s/frontend-service.yml

echo "프론트엔드 배포 완료"
