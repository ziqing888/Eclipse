#!/bin/bash

echo "Eclipse Bridge 跨链交易程序"

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

# 配置钱包和网络
wallet_path=$(prompt "请输入现有 Solana 钱包文件路径（如 /root/my-wallet.json）：")

# 验证钱包文件是否存在
if [ ! -f "$wallet_path" ]; then
    echo "钱包文件未找到，请检查路径并重试。"
    exit 1
fi

solana_address=$(prompt "请输入您的 Solana 地址：")
ethereum_private_key=$(prompt_hidden "请输入您的 Ethereum 私钥：")

# 设置 Solana 网络配置
execute_and_prompt "更新 Solana 配置..." \
    "solana config set --keypair $wallet_path && solana config set --url https://testnet.dev2.eclipsenetwork.xyz"

repeat_count=$(prompt "请输入要重复的交易次数（建议 4-5 次）：")

# 固定 Gas 限制和 Gas 价格
gas_limit="3000000"
gas_price="100000"

# 检查并克隆 Eclipse Bridge 脚本
if [ ! -d "testnet-deposit" ]; then
    execute_and_prompt "克隆 Eclipse Bridge 脚本..." \
        "git clone https://github.com/Eclipse-Laboratories-Inc/testnet-deposit && cd testnet-deposit && npm install"
else
    cd testnet-deposit
fi

# 确保依赖项安装正确
execute_and_prompt "检查并安装依赖项..." "npm install"

# 跨链交易循环
for ((i=1; i<=repeat_count; i++)); do
    execute_and_prompt "执行跨链交易（第 $i 次）..." \
    "node src/deposit.js $solana_address 0x7C9e161ebe55000a3220F972058Fb83273653a6e $gas_limit $gas_price ${ethereum_private_key:2} https://rpc.sepolia.org"
done

# 检查 Solana 余额
execute_and_prompt "检查 Solana 余额..." "solana balance --keypair $wallet_path"

balance=$(solana balance --keypair $wallet_path | awk '{print $1}')
if [ "$balance" == "0" ]; then
    echo "您的 Solana 余额为 0，请充值后重试。"
    exit 1
fi

echo "跨链交易程序执行完成。"
