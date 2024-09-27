#!/bin/bash

curl -s https://github.com/ziqing888/logo.sh/blob/main/logo.sh | bash
sleep 3

show() {
    echo -e "\033[1;34m$1\033[0m"
}

install_solana() {
    if ! command -v solana &> /dev/null; then
        show "未找到 Solana。正在安装 Solana..."
        sh -c "$(curl -sSfL https://release.solana.com/v1.18.18/install)"
        if ! grep -q 'solana' ~/.bashrc; then
            echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc
            show "已将 Solana 添加到 .bashrc 的 PATH 中。请重启终端或运行 'source ~/.bashrc' 以应用更改。"
        fi
        export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
    else
        show "Solana 已安装。"
    fi
}

setup_wallet() {
    KEYPAIR_DIR="$HOME/solana_keypairs"
    mkdir -p "$KEYPAIR_DIR"

    show "您想使用现有的钱包还是创建一个新钱包？"
    PS3="请输入您的选择 (1 或 2): "
    options=("使用现有钱包" "创建新钱包")
    select opt in "${options[@]}"; do
        case $opt in
            "使用现有钱包")
                show "正在恢复现有钱包..."
                KEYPAIR_PATH="$KEYPAIR_DIR/eclipse-import.json"
                solana-keygen recover -o "$KEYPAIR_PATH" --force
                if [[ $? -ne 0 ]]; then
                    show "恢复现有钱包失败。正在退出。"
                    exit 1
                fi
                break
                ;;
            "创建新钱包")
                show "正在创建新钱包..."
                KEYPAIR_PATH="$KEYPAIR_DIR/eclipse-new.json"
                solana-keygen new -o "$KEYPAIR_PATH" --force
                if [[ $? -ne 0 ]]; then
                    show "创建新钱包失败。正在退出。"
                    exit 1
                fi
                break
                ;;
            *) show "无效选项。请重试。" ;;
        esac
    done

    solana config set --keypair "$KEYPAIR_PATH"

    show "钱包设置完成！"
}

setup_network() {
    show "您想在主网还是测试网部署？"
    PS3="请输入您的选择 (1 或 2): "
    network_options=("主网" "测试网")
    select network_opt in "${network_options[@]}"; do
        case $network_opt in
            "主网")
                show "设置为主网..."
                NETWORK_URL="https://mainnetbeta-rpc.eclipse.xyz"
                break
                ;;
            "测试网")
                show "设置为测试网..."
                NETWORK_URL="https://testnet.dev2.eclipsenetwork.xyz"
                break
                ;;
            *) show "无效选项。请重试。" ;;
        esac
    done

    show "正在设置 Solana 配置..."
    solana config set --url "$NETWORK_URL"
    
    show "网络设置完成！"
}

create_spl_and_operations() {
    show "正在创建 SPL 令牌..."
    
    # 确保在创建令牌之前设置了密钥对
    if ! solana config get | grep -q "Keypair Path:"; then
        show "错误：Solana 配置中未设置密钥对。正在退出。"
        exit 1
    fi

    spl-token create-token --enable-metadata -p TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
    if [[ $? -ne 0 ]]; then
        show "创建 SPL 令牌失败。正在退出。"
        exit 1
    fi

    read -p "请输入您找到的令牌地址： " TOKEN_ADDRESS
    read -p "请输入您的令牌符号（例如 ZUNXBT）： " TOKEN_SYMBOL
    read -p "请输入您的令牌名称（例如 Zenith Token）： " TOKEN_NAME
    read -p "请输入您的令牌元数据 URL： " METADATA_URL

    show "正在初始化令牌元数据..."
    spl-token initialize-metadata "$TOKEN_ADDRESS" "$TOKEN_NAME" "$TOKEN_SYMBOL" "$METADATA_URL"
    if [[ $? -ne 0 ]]; then
        show "初始化令牌元数据失败。正在退出。"
        exit 1
    fi

    show "正在创建令牌账户..."
    spl-token create-account "$TOKEN_ADDRESS"
    if [[ $? -ne 0 ]]; then
        show "创建令牌账户失败。正在退出。"
        exit 1
    fi

    show "正在铸造令牌..."
    spl-token mint "$TOKEN_ADDRESS" 10000
    if [[ $? -ne 0 ]]; then
        show "铸造令牌失败。正在退出。"
        exit 1
    fi

    show "令牌操作成功完成！"
}

main_menu() {
    while true; do
        show "选择要执行的部分："
        PS3="请输入您的选择 (1, 2, 3, 4 或 5): "
        options=("安装" "钱包设置" "网络设置" "创建 SPL 令牌和操作" "退出")
        select opt in "${options[@]}"; do
            case $opt in
                "安装")
                    install_solana
                    ;;
                "钱包设置")
                    setup_wallet
                    ;;
                "网络设置")
                    setup_network
                    ;;
                "创建 SPL 令牌和操作")
                    create_spl_and_operations
                    ;;
                "退出")
                    show "正在退出脚本。"
                    exit 0
                    ;;
                *) show "无效选项。请重试。" ;;
            esac
            break
        done
    done
}

main_menu
