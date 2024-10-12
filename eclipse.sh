#!/bin/bash

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

recover_wallet() {
    local keypair_path="$1"
    solana-keygen recover -o "$keypair_path" --force
    if [[ $? -ne 0 ]]; then
        show "恢复现有钱包失败。正在退出。"
        exit 1
    fi
}

setup_wallet() {
    local keypair_dir="$HOME/solana_keypairs"
    mkdir -p "$keypair_dir"

    show "您想使用现有的钱包还是创建一个新钱包？"
    PS3="请输入您的选择 (1 或 2): "
    options=("使用现有钱包" "创建新钱包")
    select opt in "${options[@]}"; do
        case $opt in
            "使用现有钱包")
                show "正在恢复现有钱包..."
                recover_wallet "$keypair_dir/eclipse-import.json"
                break
                ;;
            "创建新钱包")
                show "正在创建新钱包..."
                solana-keygen new -o "$keypair_dir/eclipse-new.json" --force || {
                    show "创建新钱包失败。正在退出。"
                    exit 1
                }
                break
                ;;
            *) show "无效选项。请重试。" ;;
        esac
    done

    solana config set --keypair "$keypair_dir/eclipse-new.json"
    show "钱包设置完成！"
}

setup_network() {
    show "您想在主网还是测试网部署？"
    PS3="请输入您的选择 (1 或 2): "
    network_options=("主网" "测试网")
    select network_opt in "${network_options[@]}"; do
        case $network_opt in
            "主网")
                NETWORK_URL="https://mainnetbeta-rpc.eclipse.xyz"
                ;;
            "测试网")
                NETWORK_URL="https://testnet.dev2.eclipsenetwork.xyz"
                ;;
            *) show "无效选项。请重试。" && continue ;;
        esac
        break
    done

    solana config set --url "$NETWORK_URL"
    show "网络设置完成！"
}

create_spl_and_operations() {
    show "正在创建 SPL 令牌..."

    if ! solana config get | grep -q "Keypair Path:"; then
        show "错误：Solana 配置中未设置密钥对。正在退出。"
        exit 1
    fi

    spl-token create-token --enable-metadata -p TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb || {
        show "创建 SPL 令牌失败。正在退出。"
        exit 1
    }

    read -p "请输入您找到的令牌地址： " TOKEN_ADDRESS
    read -p "请输入您的令牌符号（例如 ZUNXBT）： " TOKEN_SYMBOL
    read -p "请输入您的令牌名称（例如 Zenith Token）： " TOKEN_NAME
    read -p "请输入您的令牌元数据 URL： " METADATA_URL

    show "正在初始化令牌元数据..."
    spl-token initialize-metadata "$TOKEN_ADDRESS" "$TOKEN_NAME" "$TOKEN_SYMBOL" "$METADATA_URL" || {
        show "初始化令牌元数据失败。正在退出。"
        exit 1
    }

    show "正在创建令牌账户..."
    spl-token create-account "$TOKEN_ADDRESS" || {
        show "创建令牌账户失败。正在退出。"
        exit 1
    }

    show "正在铸造令牌..."
    spl-token mint "$TOKEN_ADDRESS" 10000 || {
        show "铸造令牌失败。正在退出。"
        exit 1
    }

    show "令牌操作成功完成！"
}

main_menu() {
    while true; do
        show "选择要执行的部分："
        PS3="请输入您的选择 (1, 2, 3, 4 或 5): "
        options=("安装" "钱包设置" "网络设置" "创建 SPL 令牌和操作" "退出")
        select opt in "${options[@]}"; do
            case $opt in
                "安装") install_solana ;;
                "钱包设置") setup_wallet ;;
                "网络设置") setup_network ;;
                "创建 SPL 令牌和操作") create_spl_and_operations ;;
                "退出") show "正在退出脚本。" && exit 0 ;;
                *) show "无效选项。请重试。" ;;
            esac
            break
        done
    done
}

main_menu
