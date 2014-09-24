#!/bin/bash
# Play2 デプロイ用スクリプト
#
# 前提条件
# 1.本番サーバーにjava1.7が入っていること
# 2.本番サーバーにsbt が入っていること
#
# 手順
# 1.本番サーバーの任意の場所にソースを落とす。~/<project_name> など
# 2.プロジェクトのルートディレクトリでこのスクリプトを実行
#
# Created by Yosuke Kobayashi <yosuke032@icloud.com>


##### 各種設定 #####
# プロジェクト名 build.sbt に書いてある
PROJECT_NAME=(your_project)

# build.sbt　に記載してあるversion。特別な理由がなければ prod などに固定しておくことを推奨
VERSION=(your_version)

#本番起動場所 /usr/local/play2 など
APP_PATH=(your_app_path)

##### 実行準備 #####
# sbt dist　を実行すると./target/universal 以下 にファイルがあるはず
ZIP_FILE=./target/universal/${PROJECT_NAME}-${VERSION}.zip

#解凍先フォルダ名
FOLRDER_NAME=${PROJECT_NAME}-${VERSION}

##### 実行 #####

# 配布用zip 作成。新たにjarを落とす必要がないときは sbt publish-local dist でも可
sbt dist

# 失敗したら終了
if [ ! -f ${ZIP_FILE} ] ; then
    echo "Failed to sbt dist.can not find ${ZIP_FILE} \n"
    exit 1
fi

# unzip で解凍
unzip -o ${ZIP_FILE}

# 移動。ソース置き場( git pull 先)と本番サーバーは同じ場所。違う場合はここから先は fabric などで操作するように変更する必要がある。
# APP_PATH 以下のファイルを消しても更新しても、当然サーバー上のアプリケーションに影響はない。
cp -rf ./${FOLRDER_NAME}/* ${APP_PATH}/
rm -rf ${FOLRDER_NAME}
rm ${ZIP_FILE}

# 起動ファイルとjar群が出来ていなければ終了
if [ ! -f ${APP_PATH}/bin/${PROJECT_NAME} ]; then
    echo "Failed to create ${APP_PATH}/bin/${PROJECT_NAME} \n"
    exit 1
fi

# バックグラウンドで動かすと自動的に RUNNING_PID を吐くのでそれを見る。
if [ -f ${APP_PATH}/RUNNING_PID ]; then
    kill -9 $(cat ${APP_PATH}/RUNNING_PID)
    rm ${APP_PATH}/RUNNING_PID
fi

# 起動
${APP_PATH}/bin/${PROJECT_NAME} &

if [ $? != 0 ]; then
    echo "Failt tp Launch. please retry"
    exit 1
fi

echo "Success to deploy.but,please check it from Browser."