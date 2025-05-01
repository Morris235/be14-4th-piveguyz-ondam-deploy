#!/bin/bash
set -e

echo "ondam-ingress 배포 중..."
kubectl apply -f k8s/ingress.yml
echo "Ingress 배포 완료"

echo "접속 확인:"
echo "→ 프론트: http://ondam.localhost/"
echo "→ 백엔드: http://ondam.localhost/api/v1/counselees?memberId=1"
