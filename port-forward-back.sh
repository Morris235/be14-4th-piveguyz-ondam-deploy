#!/bin/bash
set -e

# kube 실행 테스트용
#  이 명령어는 인터랙티브하게 포워딩 유지 상태로 대기합니다. 이 스크립트를 실행하면 터미널이 점유되며, Ctrl+C로 종료해야 합니다.
echo "ondam-backend-service 포트포워딩 시작..."
kubectl port-forward service/ondam-backend-service 8083:8080 -n ondam
