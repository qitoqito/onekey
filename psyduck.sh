#!/usr/bin/env bash
echo "安装libressl中..."

libressl="/opt/psyduck/curl/bin/psyduck-curl"

# 检查目标文件是否存在
if [ ! -f "$libressl" ]; then
    chmod +x libressl.sh
    echo "未找到 $libressl，正在执行 libressl.sh..."
    # 执行 libressl.sh
    ./libressl.sh
else
    echo "已存在 $libressl，跳过执行。"
fi

echo "正在安装requests"
pip3 install requests
echo  "正在创建config.ini"
echo "本次相关参数可参照: https://github.com/qitoqito/psyduck?tab=readme-ov-file#readme"
echo "部分参数按照需求填写,如不设置请直接回车"

echo -n "请输入青龙Client ID: "
read client_id
echo -n "请输入青龙Client Secret: "
read client_secret
echo -n "请输入青龙Url端口(默认5700): "
read ql_port
if [ -z "$ql_port" ]; then
    ql_port="5700"
fi

# 构建URL
QL_URL="http://127.0.0.1:${ql_port}"

export CLIENT_ID="$client_id"
export CLIENT_SECRET="$client_secret"
export QINGLONG_PORT="$ql_port"
python3 psyduck.py
absPath=$(pwd)
echo ""

rm -rf ./psyduck
git clone https://github.com/qitoqito/psyduck.git
cp -rf ./psyduck/* /ql/data/scripts/qitoqito_psyduck
echo "正在添加订阅"
python3 psyduck.py subscriptions

cd /ql/data/scripts/qitoqito_psyduck
echo "正在添加模块"
npm install
echo "正在添加任务"
node qlCreate.js
task qitoqito_psyduck/jd_task_user.js now

if [ ! -f "$libressl" ]; then
    echo "检查不通过,请重新安装"
else
    echo "任务已完成"
fi

echo "当前网络需要开启ipv6,需要添加relayApi才能愉快运行,项目地址: https://github.com/xoyoxoyo/relayApi"
