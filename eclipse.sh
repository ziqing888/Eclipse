#!/bin/bash

echo "Eclipse Bridge 跨链交易程序 - Solana 主网"

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

# 配置钱包和网络为主网
wallet_path=$(prompt "请输入现有 Solana 钱包文件路径（如 /root/my-wallet.json）：")

# 验证钱包文件是否存在
if [ ! -f "$wallet_path" ]; then
    echo "钱包文件未找到，请检查路径并重试。"
    exit 1
fi

solana_address=$(prompt "请输入您的 Solana 地址：")
ethereum_private_key=$(prompt_hidden "请输入您的 Ethereum 私钥：")

# 设置 Solana CLI 为主网
execute_and_prompt "更新 Solana 配置..." \
    "solana config set --keypair $wallet_path && solana config set --url https://api.mainnet-beta.solana.com"

repeat_count=$(prompt "请输入要重复的交易次数（建议 4-5 次）：")

# 固定 Gas 限制和 Gas 价格
gas_limit="3000000"
gas_price="100000"

# 检查并克隆 Eclipse Bridge 脚本
if [ ! -d "testnet-deposit" ]; then
    execute_and_prompt "克隆 Eclipse Bridge 脚本..." \
        "git clone https://github.com/Eclipse-Laboratories-Inc/testnet-deposit && cd testnet-deposit && npm install --legacy-peer-deps"
else
    cd testnet-deposit
fi

# 确保依赖项安装成功
execute_and_prompt "检查并安装依赖项..." "npm install --legacy-peer-deps"

# 跨链交易循环
for ((i=1; i<=repeat_count; i++)); do
    echo "执行跨链交易（第 $i 次）..."
    echo "调用参数:"
    echo "Solana 地址: $solana_address"
    echo "EVM 地址: 8CsWQ9s8mFYZR6w6sAQqwbKF33cDzfsE3AQ4SaCypuru"
    echo "Gas 限制: $gas_limit"
    echo "Gas 价格: $gas_price"
    
    transaction_hash=$(node src/deposit.js $solana_address 8CsWQ9s8mFYZR6w6sAQqwbKF33cDzfsE3AQ4SaCypuru $gas_limit $gas_price ${ethereum_private_key:2} https://mainnet.infura.io/v3/92f9682689d945bc806e24718431219c 2>&1)

    if [ $? -eq 0 ]; then
        echo "跨链交易成功，交易哈希: $transaction_hash"
    else
        echo "跨链交易失败，请检查错误信息。"
        echo "错误输出: $transaction_hash"
    fi
done

# 检查 Solana 余额
execute_and_prompt "检查 Solana 余额..." "solana balance --keypair $wallet_path"

balance=$(solana balance --keypair $wallet_path | awk '{print $1}')
if (( $(echo "$balance <= 0" | bc -l) )); then
    echo "您的 Solana 余额为 0，请充值后重试。"
    exit 1
fi

echo "跨链交易程序执行完成。"
