#!/bin/bash
set -e

echo "ondam-frontend 배포"
kubectl apply -f k8s/ondam-front-deb.yml
kubectl apply -f k8s/ondam-front-ser.yml

echo "프론트엔드 배포 완료"
