
#!/usr/bin/env python3
import configparser
import os
import sys
import requests
import json
def main():

    os.makedirs("/ql/data/scripts/qitoqito_psyduck/config",exist_ok=True)

    # client_id = input("请输入Client ID: ").strip()
    # client_secret = input("请输入Client Secret: ").strip()
    client_id = os.getenv('CLIENT_ID')
    client_secret = os.getenv('CLIENT_SECRET')
    ql_port=os.getenv("QINGLONG_PORT")
    ql_url=f"http://127.0.0.1:{ql_port}" if ql_port else ''
    iniPath=input("请输入iniPath路径(默认在脚本库config文件夹): ").strip() or '/ql/data/scripts/qitoqito_psyduck'
    jdSign=input("请输入jdSign路径: ")
    validCookie=input("是否开启cookie过期缓存(1:开启, 0:关闭): ").strip()
    delayTo=input("请输入0到23任一数字(生成的定时任务都设置在几点后): ")
    cacheType=input("请选择缓存类型(redis:redis缓存, json:文件缓存): ")


    if cacheType=='redis':
        host=input("请输入redis地址(ip): ")
        port=input("请输入redis端口(6379): ") or 6379
        password=input("请输入redis密码: ")
        db=input("请输入redis数据库编号(2): ") or 2
    tgToken=input("请输入telegram token(通知用): ")
    tgId=input("请输入telegram id(通知用): ")
    tgProxy=input("请输入telegram代理服务器(通知用): ")
    envContent=f'''
[env]
curlPath=/opt/psyduck/curl/bin/psyduck-curl
{ "" if  iniPath else ";"}iniPath={iniPath}                        # ini文件获取路径,默认config/
{ "" if  jdSign else ";"}jdSign={jdSign}                         # 京东sign接口url
validCookie={"true" if validCookie=='1' else "false" if validCookie else "true"}           # 缓存过期cookie,开启后,脚本识别到账户过期,将缓存账户,后续脚本运行将跳过过期账户
panel= qinglong                   # 面板类型设置,账户cookie操作使用,使用cookie/type.js设置js,使用cookie/type.ini设置ini,使用青龙设置qinglong
QINGLONG_ClientId={client_id}              # 青龙ClientId
QINGLONG_ClientSecret={client_secret}         # 青龙ClientSecret
{ "" if  ql_url else ";"}QINGLONG_BaseUrl={ql_url}               # 青龙Url,一般bridge模式无需设置,host模式可能需要
index= true                       # true:账户下标从1开始计数 false:下标从0开始计数
{ "" if  delayTo else ";"}delayTo={delayTo}                        # 脚本生成的定时任务设置在几点后
;autoRelay=false                  # true:所有脚本都开启流量转发
;jdRelay=3                        # 单条转发线路最多运行多少账户
;syncRelay=20                     # 每20秒同步转发线路的用户使用情况,方便新开脚本清理转发缓存

[global]
;test=xxxx                        # 脚本全局变量

[bot]
;BOT_TOKEN=                       # Telegram Bot Token
;BOT_ROOT=                        # Telegram 用户 Id
;BOT_PROXY=                       # Telegram 代理

[proxy]
;proxyGroup=                      # 静态代理池,适用长期有效ip,需要自行创建proxy.ini
;proxyUrl=                        # 代理ip请求地址
;pool=n|-1                        # 代理池缓存数量,n为正整数时候,框架向proxyUrl获取n个ip存储在代理池,运行账号依次取出ip,数量小于n时,自动补充ip. n为-1时,取一个ip,运行账户共用此ip
;seconds=                         # 代理ip每隔几秒换新一个
;proxy=                           # 代理ip

[cache]
{"" if cacheType else ";"}type={cacheType}                  # 缓存类型,Redis缓存或json缓存
{"" if cacheType=="redis" else ";"}host={host}                           # Redis地址
{"" if cacheType=="redis" else ";"}port={port}                          # Redis端口
{"" if cacheType=="redis" else ";"}password={password}                     # Redis密码,如无设置请留空
{"" if cacheType=="redis" else ";"}db={db}                             # Redis数据库


[message]
{ "" if  tgToken else ";"}TELEGRAM_TOKEN={tgToken}                 # TELEGRAM bot token
{ "" if  tgId else ";"}TELEGRAM_ID={tgId}                   # TELEGRAM user id
{ "" if  tgProxy else ";"}TELEGRAM_ID={tgProxy}                   # TELEGRAM proxy
;BARK_URL=                        # Bark url 默认https:#api.day.app
;BARK_TOKEN=                      # Bark token
;DINGTALK_TOKEN=                  # 钉钉 token
;DINGTALK_SECRET=                 # 钉钉 secret
;PUSHPLUS_TOKEN=                  # PushPlus token
;PUSHPLUS_TOPIC=                  # PushPlus 分组id
;FTQQ_TOKEN=                      # Server酱 token
;WEIXIN_TOKEN=                    # 企业微信  token
;WXAM_TOKEN=                      # 微信AM token
'''
    print(envContent)
    with open("/ql/data/scripts/qitoqito_psyduck/config/config.ini",'w') as file:
        file.write(envContent)

    if not os.path.exists(f"{iniPath}/proxy.ini"):
        with open(f"{iniPath}/proxy.ini",'w') as file:
            file.write(f"[test]\nhttp://ip1:port\nhttp://ip2:port")
    if not os.path.exists(f"{iniPath}/jdUser.ini"):
        with open(f"{iniPath}/jdUser.ini",'w') as file:
            file.write(f"[test]\nwskey=xxx")
    if not os.path.exists(f"{iniPath}/jd.ini"):
        with open(f"{iniPath}/jd.ini",'w') as file:
            file.write(f"[jd_task_test]\ntest=xxx")
def subscriptions():
    client_id = os.getenv('CLIENT_ID')
    client_secret = os.getenv('CLIENT_SECRET')
    ql_port=os.getenv("QINGLONG_PORT")
    ql_url=f"http://127.0.0.1:{ql_port}" if ql_port else ''
    print("正在获取Token...")
    token_response = requests.get(
        f"{ql_url}/open/auth/token",
        params={"client_id": client_id, "client_secret": client_secret},
        timeout=10
    ).json()
    if token_response.get("code") != 200:
        print(f"❌ Token获取失败: {token_response.get('message')}")
        sys.exit(1)

    token = token_response["data"]["token"]
    print(f"✅ Token获取成功")

    # 2. 添加订阅

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    subscription_data = {"name":"psyduck","type":"public-repo","url":"https://github.com/qitoqito/psyduck.git","alias":"qitoqito_psyduck","schedule_type":"crontab","schedule":"23 * * * *","whitelist":"psyduck","sub_after":"cp -a /ql/data/repo/qitoqito_psyduck/. /ql/data/scripts/qitoqito_psyduck &&  task qitoqito_psyduck/qlCreate.js now","autoAddCron":False,"autoDelCron":False}

    print("正在添加订阅...")
    add_response = requests.post(
        f"{ql_url}/open/subscriptions",
        json=subscription_data,
        headers=headers,
        timeout=30
    ).json()

    if add_response.get("code") == 200:
        print(f"✅ 订阅添加成功")
    else:
        print(f"❌ 订阅添加失败: {add_response.get('message')},可能已有订阅")

if __name__ == "__main__":
    args = sys.argv[1:]
    type=args and args[0]
    if type=='subscriptions':
        subscriptions()
    else:
        main()
