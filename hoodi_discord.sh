#!/bin/bash

source /root/.bashrc

read -p "输入 Discord 用户名: " discordName
read -p "输入私钥: " private_key

# 设置路径变量
CONTRACT_PATH="/root/my-drosera-trap/src/Trap.sol"
PROJECT_PATH="/root/my-drosera-trap"
TOML_FILE="$PROJECT_PATH/drosera.toml"
TOML_BACKUP="$PROJECT_PATH/drosera.toml.bak"
RESPONSE_CONTRACT="0x25E2CeF36020A736CF8a4D2cAdD2EBE3940F4608"

# 写入 Trap.sol 合约代码
cat > "$CONTRACT_PATH" <<EOF
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

interface IMockResponse {
    function isActive() external view returns (bool);
}

contract Trap is ITrap {
    address public constant RESPONSE_CONTRACT = $RESPONSE_CONTRACT;
    string constant discordName = "$discordName";

    function collect() external view returns (bytes memory) {
        bool active = IMockResponse(RESPONSE_CONTRACT).isActive();
        return abi.encode(active, discordName);
    }

    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory) {
        (bool active, string memory name) = abi.decode(data[0], (bool, string));
        if (!active || bytes(name).length == 0) {
            return (false, bytes(""));
        }
        return (true, abi.encode(name));
    }
}
EOF

# 备份 drosera.toml 文件
if [ -f "$TOML_FILE" ]; then
    cp "$TOML_FILE" "$TOML_BACKUP"
    echo "已备份 drosera.toml 为 drosera.toml.bak"
else
    echo "未找到 drosera.toml，退出。"
    exit 1
fi

# 替换 drosera.toml 中的配置
sed -i 's|path = ".*"|path = "out/Trap.sol/Trap.json"|' "$TOML_FILE"
sed -i 's|response_contract = ".*"|response_contract = "'"$RESPONSE_CONTRACT"'"|' "$TOML_FILE"
sed -i 's|response_function = ".*"|response_function = "respondWithDiscordName(string)"|' "$TOML_FILE"

# 编译合约
cd "$PROJECT_PATH" || exit 1
forge build

# 执行 drosera apply
DROSERA_PRIVATE_KEY="$private_key" drosera apply
