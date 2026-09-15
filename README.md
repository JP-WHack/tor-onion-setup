<div align="center">

# Tor Hidden Service 自動セットアップ

**教育目的の .onion サイト構築ツール - ワンコマンドで展開可能**

![Bash](https://img.shields.io/badge/Bash-自動化-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Raspberry_Pi_%7C_Debian-A22846?style=for-the-badge&logo=raspberrypi&logoColor=white)
![License](https://img.shields.io/badge/License-Educational-FF8C00?style=for-the-badge)

</div>

---

## 📖 概要

Debian ベースシステム上で Tor Hidden Service（.onion サイト）を自動展開するスクリプトです。Tor、Nginx、および関連コンポーネントの設定を効率化し、教育目的およびプライバシー研究のための匿名 Web サービスの迅速な展開を可能にします。

---

## ✨ 主な機能

* 完全自動セットアッププロセス
* .onion アドレスの自動生成
* Web サーバー（Nginx）の事前設定
* Tor v3 プロトコル対応
* 冪等性のある実行（安全に再実行可能）
* 包括的なエラーハンドリング
* サービス自動起動設定

---

## 📋 システム要件

* Debian 11 または 12（Raspberry Pi OS 対応）
* root または sudo 権限
* インターネット接続
* 最低 512MB の RAM
* 1GB の空きディスク容量

---

## 🚀 クイックスタート

セットアップスクリプトを実行:

```bash
sudo bash onion.sh
```

スクリプトは以下を自動的に実行します:

1. 必要なパッケージのインストール（Tor、Nginx）
2. Tor Hidden Service の設定
3. Web サーバーのセットアップ
4. .onion アドレスの生成
5. 全サービスの起動

セットアップは通常 1〜2 分で完了します。

---

## 💻 使用方法

### 初期セットアップ

```bash
# スクリプトをダウンロード
wget URL

# 実行権限を付与
chmod +x onion.sh

# root 権限で実行
sudo bash onion.sh
```

### サービスへのアクセス

完了すると、固有の .onion アドレスが表示されます:

```
あなたの .onion アドレス:
----------------------------------------
  abc123xyz456def789.onion
----------------------------------------
```

Tor Browser を使用してアクセス:

1. Tor Browser をダウンロード: https://www.torproject.org/download/
2. Tor Browser を起動
3. .onion アドレスを入力
4. Hidden Service にアクセス

---

## 🏗️ 技術アーキテクチャ

```
クライアント (Tor Browser)
        |
        v
    Tor ネットワーク
        |
        v
あなたの Hidden Service (.onion)
        |
        v
    Tor (ポー〈80 -> 127.0.0.1:8080)
        |
        v
    Nginx (127.0.0.1:8080)
        |
        v
    Web コンテンツ (/var/www/onion)
```

---

## 🔧 サービス管理

### .onion アドレスの確認

```bash
sudo cat /var/lib/tor/hidden_service/hostname
```

### サービスの再起動

```bash
sudo systemctl restart tor@default nginx
```

### サービスステータスの確認

```bash
systemctl status tor@default nginx
```

### ログの確認

```bash
# Tor ログ
journalctl -u tor@default -f

# Nginx ログ
tail -f /var/log/nginx/onion_error.log
tail -f /var/log/nginx/onion_access.log
```

---

## ⚙️ カスタマイズ

### Web コンテンツの変更

HTML ファイルを編集:

```bash
sudo nano /var/www/onion/index.html
```

変更後、Nginx をリロード:

```bash
sudo systemctl reload nginx
```

### ポート設定の変更

Tor 設定を編集:

```bash
sudo nano /etc/tor/torrc
```

HiddenServicePort 指示を変更して再起動:

```bash
sudo systemctl restart tor@default
```

---

## 🔍 トラブルシューティング

### アドレスが生成されない

Tor サービスのステータスとログを確認:

```bash
systemctl status tor@default
journalctl -u tor@default -n 50
```

ディレクトリの権限を確認:

```bash
ls -la /var/lib/tor/hidden_service
```

### 接続の問題

サービスが稼働していることを確認:

```bash
systemctl is-active tor@default nginx
```

設定を検証:

```bash
sudo nginx -t
```

### セットアップの再実行

スクリプトは冪等性があり、安全に再実行できます:

```bash
sudo bash onion.sh
```

---

## 🎓 教育への応用

このツールは以下の学習を促進します:

* Tor ネットワークアーキテクチャとプロトコル
* Hidden Service の展開と運用
* 匿名通信システム
* プライバシー保護技術
* Web サーバー設定
* Linux システム管理

---

## ✅ 許可された使用範囲

本ソフトウェアは以下の目的でのみ使用可能です:

**許可される用途:**

* 教育研究と学習
* プライバシー技術の学習
* 管理された環境での個人実験
* 学術的課題とプロジェクト

**禁止される用途:**

* あらゆる種類の違法行為
* 違法コンテンツのホスティング
* 利用規約の違反
* 嫌がらせや他者への危害
* 著作権侵害

ユーザーは、使用が適用されるすべての法律および規制に準拠していることを確保する全責任を負います。Tor ネットワークの匿名性機能は、ユーザーを法的責任から免除するものではありません。

---

## 🔒 セキュリティに関する考慮事項

* Hidden Service は匿名性を提供しますが、絶対的なセキュリティではありません
* サーバーインフラストラクチャは適切に保護する必要があります
* 定期的なセキュリティアップデートを適用してください
* アクセスログを監視してください
* 機密性の高いアプリケーションには追加の強化が必要です

---

## 📚 参考資料

* Tor プロジェクトドキュメント: https://www.torproject.org/docs/
* Hidden Service ガイド: https://community.torproject.org/onion-services/
* Tor セキュリティベストプラクティス: https://support.torproject.org/

---

## 💛 開発支援

このツールが教育目標の達成に役立った場合、継続的な開発への貢献をご検討ください:

**Bitcoin (BTC):**

```
bc1q2tf2d7ts89amthax70mf64p9ez7c9xz56snku0
```

すべての寄付は、プライバシーとセキュリティ研究のための無料教育リソースの維持を支援します。

---

## 🌐 教育理念

本プロジェクトは、プライバシー技術におけるアクセス可能な教育への取り組みを維持しています。すべての機能は無料で提供され、ソフトウェアは教育利用のために常に自由に利用可能です。

---

## ⚠️ 免責事項

本ソフトウェアは教育目的でのみ提供されています。ユーザーは、使用が適用される法律、規制、倫理基準に準拠していることを確保する完全な責任を負います。作成者は本ソフトウェアの誤用に対する一切の責任を負いません。

---

<div align="center">

*プライバシー技術研究のための教育ツール*

</div>
