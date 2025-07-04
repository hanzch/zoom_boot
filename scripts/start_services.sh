#!/bin/bash

# ====================================
# ZoomJ):h��/�,
# ====================================

set -e

# �r�I
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() { echo -e "${BLUE}=== $1 ===${NC}"; }

# ��Ł��
check_files() {
    print_header "��y��"
    
    if [ ! -f "package.json" ]; then
        print_error "package.json ��X("
        exit 1
    fi
    
    if [ ! -f "server.js" ]; then
        print_error "server.js ��X("
        exit 1
    fi
    
    if [ ! -f ".env" ]; then
        print_warning ".env ��X(( .env.example"
        if [ -f ".env.example" ]; then
            cp .env.example .env
            print_status ".env ������Mn"
        else
            print_error ".env.example _X(�HMn����"
            exit 1
        fi
    fi
    
    print_status "y����"
}

# �寃Mn
check_env() {
    print_header "�寃Mn"
    
    source .env
    
    if [ -z "$ZOOM_CLIENT_ID" ] || [ "$ZOOM_CLIENT_ID" = "your_zoom_client_id_here" ]; then
        print_error "�( .env ��-Mn ZOOM_CLIENT_ID"
        exit 1
    fi
    
    if [ -z "$ZOOM_CLIENT_SECRET" ] || [ "$ZOOM_CLIENT_SECRET" = "your_zoom_client_secret_here" ]; then
        print_error "�( .env ��-Mn ZOOM_CLIENT_SECRET"
        exit 1
    fi
    
    if [ -z "$ZOOM_VERIFICATION_TOKEN" ] || [ "$ZOOM_VERIFICATION_TOKEN" = "your_zoom_verification_token_here" ]; then
        print_error "�( .env ��-Mn ZOOM_VERIFICATION_TOKEN"
        exit 1
    fi
    
    print_status "��Mn���"
}

# �ŝV
install_deps() {
    print_header "��v�ŝV"
    
    if [ ! -d "node_modules" ]; then
        print_status "��npm�V..."
        npm install
    else
        print_status "�V�X(�ǉ�"
    fi
}

# 	�/��
choose_start_method() {
    print_header "	�/��"
    
    echo "�	�/��"
    echo "  1) ��/� (npm start)"
    echo "  2)  �! (npm run dev)"
    echo "  3) PM2/� (npm run pm2:start)"
    echo "  4) �/� (nohup)"
    
    read -p "��e	� (1-4): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            start_normal
            ;;
        2)
            start_dev
            ;;
        3)
            start_pm2
            ;;
        4)
            start_background
            ;;
        *)
            print_warning "�H	�(ؤ�/�"
            start_normal
            ;;
    esac
}

# ��/�
start_normal() {
    print_status "��/��..."
    npm start
}

#  �!/�
start_dev() {
    print_status " �!/�..."
    if ! command -v nodemon &> /dev/null; then
        print_status "�� nodemon..."
        npm install -g nodemon
    fi
    npm run dev
}

# PM2/�
start_pm2() {
    print_status "PM2/��..."
    
    if ! command -v pm2 &> /dev/null; then
        print_status "�� PM2..."
        npm install -g pm2
    fi
    
    # ��/&��(�L
    if pm2 list | grep -q "zoom-bot"; then
        print_warning "zoom-bot ��X(�/-..."
        npm run pm2:restart
    else
        npm run pm2:start
    fi
    
    echo ""
    print_status "	(�PM2}�"
    echo "  npm run pm2:status  - ��"
    echo "  npm run pm2:logs    - ���"
    echo "  npm run pm2:restart - �/�"
    echo "  npm run pm2:stop    - \b�"
}

# �/�
start_background() {
    print_status "�/��..."
    
    # ����U
    mkdir -p logs
    
    # �/�
    nohup npm start > logs/service.log 2>&1 &
    
    PID=$!
    echo $PID > logs/service.pid
    
    print_status "��(�/�PID: $PID"
    print_status "�ׇ�: logs/service.log"
    print_status "\b�: kill $PID"
}

# >:��o
show_service_info() {
    print_header "��o"
    
    PORT=${PORT:-3001}
    DOMAIN=${DOMAIN_NAME:-localhost}
    
    echo "=� ��/�"
    echo ""
    echo "=� ,0��"
    echo "  - ;u: http://localhost:$PORT"
    echo "  - e���: http://localhost:$PORT/health"
    echo "  - Kէ6�: http://localhost:$PORT/test"
    echo ""
    
    if [ "$DOMAIN" != "localhost" ] && [ "$DOMAIN" != "your-domain.com" ]; then
        echo "< lQ�� Mn��	"
        echo "  - ;u: https://$DOMAIN"
        echo "  - Webhook: https://$DOMAIN/webhook"
        echo "  - OAuth�: https://$DOMAIN/oauth/callback"
        echo ""
    fi
    
    echo "=� �:"
    echo "  - n�2k�A��� $PORT"
    echo "  - �����(PM2���"
    echo "  - Mn���/HTTPS"
}

# ;�p
main() {
    print_header "ZoomJ):h��/�"
    
    check_files
    check_env
    install_deps
    
    # ��Л��p��(���/��
    case "$1" in
        "normal"|"start")
            start_normal
            ;;
        "dev")
            start_dev
            ;;
        "pm2")
            start_pm2
            ;;
        "background"|"bg")
            start_background
            ;;
        *)
            choose_start_method
            ;;
    esac
    
    show_service_info
}

# >:.�
show_help() {
    echo "(�: $0 [	y]"
    echo ""
    echo "	y:"
    echo "  normal/start    - ��/�"
    echo "  dev            -  �!/�"
    echo "  pm2            - PM2/�"
    echo "  background/bg  - �/�"
    echo "  help           - >:.�"
    echo ""
    echo ":�:"
    echo "  $0              # ��	�/��"
    echo "  $0 pm2          # ��(PM2/�"
    echo "  $0 dev          #  �!/�"
}

# �p
if [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# �L;�p
main "$@"