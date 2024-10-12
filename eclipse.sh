#!/bin/bash

echo "Eclipse 部署程序 - Happy Cuan Airdrop"

prompt() {
    read -p "$1" response
    echo $response
}

prompt_hidden() {
    read -s -p "$1" response
    echo $response
}

execute_and_prompt() {
    echo -e "\n$1"
    eval "$2"
    read -p "按 [Enter] 键继续..."
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    else
        return 0
    fi
}

cd $HOME

execute_and_prompt "正在更新系统依赖项..." "sudo apt update && sudo apt upgrade -y"

if ! check_command rustc; then
    execute_and_prompt "安装 Rust..." "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    source "$HOME/.cargo/env"
    execute_and_prompt "检查 Rust 版本..." "rustc --version"
else
    echo "Rust 已安装，跳过安装。"
fi

if ! check_command solana; then
    execute_and_prompt "安装 Solana CLI..." 'sh -c "$(curl -sSfL https://release.solana.com/stable/install)"'
    export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"
    execute_and_prompt "检查 Solana 版本..." "solana --version"
else
    echo "Solana CLI 已安装，跳过安装。"
fi

if ! check_command npm; then
    execute_and_prompt "安装 npm..." "sudo apt-get install -y npm"
    execute_and_prompt "检查 npm 版本..." "npm --version"
else
    echo "npm 已安装，跳过安装。"
fi

if ! check_command anchor; then
    execute_and_prompt "安装 Anchor CLI..." "cargo install --git https://github.com/project-serum/anchor anchor-cli --locked"
    export PATH="$HOME/.cargo/bin:$PATH"
    execute_and_prompt "检查 Anchor 版本..." "anchor --version"
else
    echo "Anchor CLI 已安装，跳过安装。"
fi

# 使用现有钱包地址
wallet_path=$(prompt "请输入现有钱包文件的路径（如 /root/my-wallet.json）：")

# 设置 Solana CLI 使用现有钱包文件
execute_and_prompt "更新 Solana 配置..." "solana config set --keypair $wallet_path && solana config set --url https://testnet.dev2.eclipsenetwork.xyz"
execute_and_prompt "检查 Solana 地址..." "solana address --keypair $wallet_path"

echo -e "\n将您的 BIP39 密钥短语导入 OKX、BITGET、METAMASK 或 RABBY，以获取 EVM 地址用于申领 Sepolia 测试网代币。"
echo -e "请使用以下水龙头链接获取测试 ETH：\nhttps://faucet.quicknode.com/ethereum/sepolia\nhttps://faucets.chain.link/\nhttps://www.infura.io/faucet"
read -p "按 [Enter] 键继续..."

if [ -d "testnet-deposit" ]; then
    execute_and_prompt "删除已存在的 testnet-deposit 文件夹..." "rm -rf testnet-deposit"
fi

execute_and_prompt "克隆 Eclipse Bridge 脚本..." "git clone https://github.com/Eclipse-Laboratories-Inc/testnet-deposit ~/testnet-deposit && cd ~/testnet-deposit && npm install"

solana_address=$(prompt "请输入您的 Solana 地址：")
ethereum_private_key=$(prompt_hidden "请输入您的 Ethereum 私钥：")

while :; do
    repeat_count=$(prompt "请输入交易重复次数（建议 4-5 次）：")
    if [[ "$repeat_count" =~ ^[0-9]+$ ]]; then
        break
    else
        echo "请输入有效的数字。"
    fi
done

gas_limit="3000000"
gas_price="100000"

for ((i=1; i<=repeat_count; i++)); do
    execute_and_prompt "运行桥接脚本（第 $i 次）..." \
    "node ~/testnet-deposit/src/deposit.js $solana_address 0x7C9e161ebe55000a3220F972058Fb83273653a6e $gas_limit $gas_price ${ethereum_private_key:2} https://rpc.sepolia.org"
done

execute_and_prompt "检查 Solana 余额..." "solana balance --keypair $wallet_path"

balance=$(solana balance --keypair $wallet_path | awk '{print $1}')
if [ "$balance" == "0" ]; then
    echo "您的 Solana 余额为 0，请充值后重试。"
    exit 1
fi

execute_and_prompt "创建代币..." "spl-token create-token --enable-metadata -p TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"

token_address=$(prompt "请输入您的代币地址：")
execute_and_prompt "创建代币账户..." "spl-token create-account $token_address"

execute_and_prompt "铸造代币..." "spl-token mint $token_address 10000"
execute_and_prompt "检查代币账户..." "spl-token accounts"

echo -e "\n提交反馈至：https://docs.google.com/forms/d/e/1FAIpQLSfJQCFBKHpiy2HVw9lTjCj7k0BqNKnP6G1cd0YdKhaPLWD-AA/viewform?pli=1"
execute_and_prompt "检查程序地址..." "solana address --keypair $wallet_path"

echo "程序执行完成。"

