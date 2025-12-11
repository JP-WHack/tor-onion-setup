#!/bin/bash

# Tor Hidden Service 自動セットアップスクリプト
# Raspberry PiおよびDebianベースシステム最適化版 v3
# tor@default対応 - 教育目的専用

set -e

echo "==================================="
echo "Tor Hidden Service セットアップ開始"
echo "==================================="

# ターミナル色コード
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 設定変数
HIDDEN_SERVICE_DIR="/var/lib/tor/hidden_service"
TOR_CONFIG="/etc/tor/torrc"
TOR_CONFIG_MARKER="# --- START_HIDDEN_SERVICE_CONFIG ---"
NGINX_SITE_CONFIG="/etc/nginx/sites-available/onion"
WEB_ROOT="/var/www/onion"

# root権限チェック
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}このスクリプトはroot権限が必要です${NC}"
    echo "使用方法: sudo bash onion.sh"
    exit 1
fi

## ステップ0: 既存設定の完全クリーンアップ
echo -e "${BLUE}[0/7] 既存設定の完全クリーンアップを実行中...${NC}"

# Nginxを完全停止
echo "  Nginxサービスを停止中..."
systemctl stop nginx 2>/dev/null || true
sleep 1

# 残存プロセスを強制終了
pkill -9 nginx 2>/dev/null || true
sleep 1

# Torサービスを停止（両サービスタイプ）
echo "  Torサービスを停止中..."
systemctl stop tor 2>/dev/null || true
systemctl stop tor@default 2>/dev/null || true
sleep 2

# Torプロセスの終了を確認
echo "  Torプロセスの終了を確認中..."
for i in {1..15}; do
    if ! pgrep -x "tor" > /dev/null; then
        echo "    Torプロセスが正常に終了しました"
        break
    fi
    if [ $i -eq 15 ]; then
        echo -e "${YELLOW}    警告: Torプロセスを強制終了します${NC}"
        pkill -9 tor 2>/dev/null || true
        sleep 1
    fi
    sleep 1
done

# Nginx設定ファイルの削除
echo "  Nginx設定ファイルを削除中..."
rm -f "$NGINX_SITE_CONFIG"
rm -f /etc/nginx/sites-enabled/onion
rm -f /etc/nginx/sites-enabled/default
rm -rf "$WEB_ROOT"

# Hidden Serviceディレクトリの完全削除
echo "  Hidden Serviceディレクトリを削除中..."
if [ -d "$HIDDEN_SERVICE_DIR" ]; then
    chattr -i "$HIDDEN_SERVICE_DIR"/* 2>/dev/null || true
    chmod -R 777 "$HIDDEN_SERVICE_DIR" 2>/dev/null || true
    rm -rf "$HIDDEN_SERVICE_DIR"
fi

# Torキャッシュとロックファイルをクリア
echo "  Torキャッシュをクリア中..."
rm -rf /var/lib/tor/cached-* 2>/dev/null || true
rm -rf /var/lib/tor/lock 2>/dev/null || true
rm -rf /var/lib/tor/state 2>/dev/null || true

# Tor設定ファイルをクリーンアップ
echo "  Tor設定ファイルをクリーンアップ中..."
if [ -f "$TOR_CONFIG" ]; then
    sed -i "/${TOR_CONFIG_MARKER}/,/^# --- END_HIDDEN_SERVICE_CONFIG ---/d" "$TOR_CONFIG"
    sed -i '/^$/N;/^\n$/D' "$TOR_CONFIG"
fi

echo -e "${GREEN}  クリーンアップが完了しました${NC}"
sleep 1

## ステップ1: 必要なパッケージのインストール
echo -e "${BLUE}[1/7] 必要なパッケージを確認中...${NC}"
if ! command -v tor &> /dev/null || ! command -v nginx &> /dev/null; then
    echo "  パッケージをインストール中..."
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y tor nginx > /dev/null 2>&1
    echo "  インストールが完了しました"
else
    echo "  パッケージは既にインストールされています"
fi

## ステップ2: Hidden Serviceディレクトリの作成
echo -e "${BLUE}[2/7] Hidden Serviceディレクトリを作成中...${NC}"

mkdir -p "$HIDDEN_SERVICE_DIR"
chown -R debian-tor:debian-tor "$HIDDEN_SERVICE_DIR"
chmod 700 "$HIDDEN_SERVICE_DIR"

echo "  ディレクトリが正常に作成されました"

## ステップ3: Tor設定の更新
echo -e "${BLUE}[3/7] Tor設定を更新中...${NC}"

# 初回のみバックアップを作成
if [ ! -f "${TOR_CONFIG}.original" ]; then
    echo "  設定ファイルのバックアップを作成中..."
    cp "$TOR_CONFIG" "${TOR_CONFIG}.original"
fi

# Hidden Service設定を追記
echo "  新しい設定を追加中..."
cat >> "$TOR_CONFIG" << EOF

$TOR_CONFIG_MARKER
# Hidden Service設定 (生成日時: $(date))
HiddenServiceDir $HIDDEN_SERVICE_DIR
HiddenServicePort 80 127.0.0.1:8080
# --- END_HIDDEN_SERVICE_CONFIG ---
EOF

echo "  Tor設定が完了しました"

## ステップ4: Webコンテンツの作成
echo -e "${BLUE}[4/7] Webコンテンツを作成中...${NC}"

mkdir -p "$WEB_ROOT"

cat > "$WEB_ROOT/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tor Hidden Service</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 50px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            text-align: center;
            max-width: 600px;
            animation: fadeIn 0.6s ease-in;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        h1 {
            color: #667eea;
            font-size: 3em;
            margin: 0 0 20px 0;
            animation: pulse 2s ease-in-out infinite;
        }
        @keyframes pulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.05); }
        }
        p {
            color: #555;
            font-size: 1.2em;
            line-height: 1.6;
            margin: 10px 0;
        }
        .info {
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            border-radius: 10px;
            padding: 20px;
            margin-top: 30px;
        }
        .badge {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9em;
            margin: 5px;
        }
        .timestamp {
            color: #888;
            font-size: 0.9em;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Tor Hidden Service</h1>
        <p>このサイトは.onionドメインで稼働しています</p>
        <div class="info">
            <p><strong>接続情報</strong></p>
            <div>
                <span class="badge">Torネットワーク</span>
                <span class="badge">匿名</span>
                <span class="badge">暗号化</span>
            </div>
            <p style="margin-top: 15px;">Torネットワーク経由でアクセス中</p>
            <p>プライバシーと匿名性が保護されています</p>
        </div>
        <p class="timestamp">生成日時: <script>document.write(new Date().toLocaleString('ja-JP'));</script></p>
    </div>
</body>
</html>
EOF

chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"

echo "  Webコンテンツが正常に作成されました"

## ステップ5: Nginx設定
echo -e "${BLUE}[5/7] Nginxを設定中...${NC}"

cat > "$NGINX_SITE_CONFIG" << 'EOF'
server {
    listen 127.0.0.1:8080;
    server_name localhost;
    
    root /var/www/onion;
    index index.html;
    
    access_log /var/log/nginx/onion_access.log;
    error_log /var/log/nginx/onion_error.log;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer" always;
    add_header Cache-Control "no-store, no-cache, must-revalidate" always;
}
EOF

ln -sf "$NGINX_SITE_CONFIG" /etc/nginx/sites-enabled/onion
rm -f /etc/nginx/sites-enabled/default

echo "  Nginx設定をテスト中..."
if nginx -t 2>&1 | grep -q "successful"; then
    echo -e "${GREEN}    設定テストに合格しました${NC}"
else
    echo -e "${RED}    設定テストに失敗しました${NC}"
    nginx -t
    exit 1
fi

echo "  Nginx設定が完了しました"

## ステップ6: サービスの起動
echo -e "${BLUE}[6/7] サービスを起動中...${NC}"

echo "  Nginxを起動中..."
systemctl restart nginx
sleep 1

if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}    Nginxが正常に起動しました${NC}"
else
    echo -e "${RED}    Nginxの起動に失敗しました${NC}"
    systemctl status nginx --no-pager
    exit 1
fi

echo "  Torを起動中..."
systemctl enable tor@default 2>/dev/null || true
systemctl restart tor@default
sleep 2

if systemctl is-active --quiet tor@default; then
    echo -e "${GREEN}    Torが正常に起動しました${NC}"
else
    echo -e "${RED}    Torの起動に失敗しました${NC}"
    echo ""
    echo "詳細ログ:"
    systemctl status tor@default --no-pager
    echo ""
    journalctl -u tor@default -n 50 --no-pager
    exit 1
fi

## ステップ7: .onionアドレスの生成を待機
echo -e "${BLUE}[7/7] .onionアドレスの生成を待機中...${NC}"

WAIT_COUNT=0
MAX_WAIT=60
HOSTNAME_FILE="$HIDDEN_SERVICE_DIR/hostname"

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    if [ -f "$HOSTNAME_FILE" ] && [ -s "$HOSTNAME_FILE" ]; then
        echo -e "${GREEN}  アドレスが正常に生成されました${NC}"
        break
    fi
    
    if [ $((WAIT_COUNT % 5)) -eq 0 ]; then
        echo "  待機中... ($WAIT_COUNT秒経過)"
    fi
    
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
done

echo ""
echo "==================================="

if [ -f "$HOSTNAME_FILE" ] && [ -s "$HOSTNAME_FILE" ]; then
    ONION_ADDRESS=$(cat "$HOSTNAME_FILE")
    
    echo -e "${GREEN}    セットアップが正常に完了しました${NC}"
    echo "==================================="
    echo ""
    echo -e "${GREEN}あなたの.onionアドレス:${NC}"
    echo "----------------------------------------"
    echo "  $ONION_ADDRESS"
    echo "----------------------------------------"
    echo ""
    echo -e "${YELLOW}アクセス方法:${NC}"
    echo "  1. Tor Browserを起動"
    echo "  2. 上記のアドレスをコピーして貼り付け"
    echo "  3. Hidden Serviceにアクセス"
    echo ""
    echo -e "${GREEN}サービス管理コマンド:${NC}"
    echo "  ステータス確認:"
    echo "    systemctl status tor@default nginx"
    echo ""
    echo "  サービス再起動:"
    echo "    sudo systemctl restart tor@default nginx"
    echo ""
    echo "  .onionアドレス確認:"
    echo "    sudo cat $HOSTNAME_FILE"
    echo ""
    echo "  ログ確認:"
    echo "    journalctl -u tor@default -f"
    echo "    tail -f /var/log/nginx/onion_error.log"
    echo ""
    
    systemctl enable tor@default nginx 2>/dev/null
    
    echo -e "${GREEN}サービスは自動起動に設定されました${NC}"
    echo ""
    echo "==================================="
    echo "   すべての設定が完了しました"
    echo "==================================="
    echo ""
    
else
    echo -e "${RED}  エラー: .onionアドレスの生成に失敗しました${NC}"
    echo "==================================="
    echo ""
    echo -e "${YELLOW}トラブルシューティング手順:${NC}"
    echo ""
    echo "1. Torログを確認:"
    echo "   journalctl -u tor@default -n 100"
    echo ""
    echo "2. Hidden Serviceディレクトリの権限確認:"
    echo "   ls -la $HIDDEN_SERVICE_DIR"
    echo ""
    echo "3. Tor設定の確認:"
    echo "   grep -A 5 'HiddenService' $TOR_CONFIG"
    echo ""
    echo "4. サービスステータス確認:"
    echo "   systemctl status tor@default nginx"
    echo ""
    echo "5. スクリプトの再実行:"
    echo "   sudo bash $0"
    echo ""
    exit 1
fi
