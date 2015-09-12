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

#ソース場所 /home/play2/my_project など
PROJECT_PATH=(your_app_path)

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

# 前回のJar群を消しておく。当然サーバー上のアプリケーションに影響はない。
rm -rf ${FOLRDER_NAME}

# unzip で解凍
unzip -o ${ZIP_FILE}

# 一つ前のzipは念のためとっておく
mv ${ZIP_FILE} ${ZIP_FILE}.bak

# 起動ファイルとjar群が出来ていなければ終了
if [ ! -f ${PROJECT_PATH}/${FOLRDER_NAME}/bin/${PROJECT_NAME} ]; then
    echo "Failed to create ${PROJECT_PATH}/${FOLRDER_NAME}/bin/${PROJECT_NAME} \n"
    exit 1
fi

# バックグラウンドで動かすと自動的に RUNNING_PID を吐くのでそれを見る。
if [ -f ${PROJECT_PATH}/${FOLRDER_NAME}/RUNNING_PID ]; then
    kill $(cat ${PROJECT_PATH}/${FOLRDER_NAME}/RUNNING_PID)
    rm -f ${PROJECT_PATH}/${FOLRDER_NAME}/RUNNING_PID
fi

# 起動
${PROJECT_PATH}/${FOLRDER_NAME}/bin/${PROJECT_NAME} &

if [ $? != 0 ]; then
    echo "Failed to Launch. please retry"
    exit 1
fi

echo "Success to deploy.but,please check it from Browser."
