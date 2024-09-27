# E在 Eclipse 主网或 Eclipse 测试网上部署代币合约
先决条件
您可以在 Codespace [已测试] 、Gitpod、VPS 或任何 Linux 系统上运行此脚本
一个需要在 eclipse 主网上拥有$ETH
您可以从官方桥桥接以在 Eclipse 主网上获得 ETH
如果您想在 Eclipse 上获取测试网$ETH以在 Eclipse 测试网上部署代币合约，请使用此桥从 Sepolia 测试网获取 Eclipse ETH
访问此网站： 元数据 Url 生成器
输入您的 、 、 ，然后输入您的令牌token nametoken symbolDescriptionupload a pic
您将获得一个 URL，复制并保存它
此外，在脚本执行过程中，它将询问 和 ，使用上述网站中使用的相同符号和名称 utoken nametoken symbol
重要信息
如果您选择 ，它将要求您输入 Passphrase。在这里你需要输入一个密码（非常小），还要确保记下这个密码。它会显示你的钱包助记词，公钥写下来，最后在合约部署后，使用这个命令create new wallet
cat $HOME/solana_keypairs/eclipse-new.json
你会得到这样的输出 [127， 125， 28， ....， 56， 68， 89]，复制包括第 3 个括号在内的整个输出，然后打开 Backpack Extension，点击导入钱包，然后选择 Eclipse，然后粘贴包括第 3 个括号在内的整个输出，它将导入你用于合约部署的钱包
现在转到设置，然后使用 Back pack wallet 导出此钱包的私有，并将其写下来，完成 ✅
如果你选择，在导入使用你的助记词时，它会询问你是否有任何密码，你应该按下按钮，然后它会显示一个钱包，你可能不熟悉这个，别担心，没关系，其实我们可以用单个助记词创建很多钱包地址，所以在冲突部署后使用此命令import existing walletEnter
cat $HOME/solana_keypairs/eclipse-import.json
你会得到这样的输出 [127， 125， 28， ....， 56， 68， 89]，复制包括第 3 个括号在内的整个输出，然后打开 Backpack Extension，点击导入钱包，然后选择 Eclipse，然后粘贴包括第 3 个括号在内的整个输出，它将导入你用于合约部署的钱包
现在转到设置，然后使用 Back pack wallet 导出此钱包的私有，并将其写下来，完成 ✅
安装clipse
