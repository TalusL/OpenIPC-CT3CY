#!/bin/sh

# 配置参数 - 可根据需要修改
DAY_THRESHOLD=1400       # 低于此值进入白天模式
NIGHT_THRESHOLD=10000    # 高于此值进入黑夜模式
CHECK_INTERVAL=5         # 检查间隔时间(秒)
METRICS_URL="localhost/metrics/isp?value=isp_again"  # 获取亮度值的URL

# 初始模式，默认为未知
current_mode="day"

# 函数：切换到白天模式
switch_to_day() {
    echo "切换到白天模式"
    wget -q -T1 localhost/night/off -O -
    current_mode="day"
}

# 函数：切换到黑夜模式
switch_to_night() {
    echo "切换到黑夜模式"
    wget -q -T1 localhost/night/on -O -
    current_mode="night"
}

echo "日夜模式切换脚本启动..."
echo "白天阈值: $DAY_THRESHOLD, 黑夜阈值: $NIGHT_THRESHOLD, 检查间隔: $CHECK_INTERVAL秒"
switch_to_day

# 主循环
while true; do
    # 获取亮度值
    daynight_value=$(wget -q -T1 $METRICS_URL -O -)

    # 检查获取值是否成功
    if [ -z "$daynight_value" ]; then
        echo "获取亮度值失败，将重试..."
        sleep $CHECK_INTERVAL
        continue
    fi

    echo "当前亮度值: $daynight_value, 当前模式: $current_mode"

    # 根据当前模式和亮度值决定是否切换模式
    if [ "$current_mode" = "day" ] || [ -z "$current_mode" ]; then
        # 当前是白天模式或初始状态，检查是否需要切换到黑夜模式
        if [ $daynight_value -gt $NIGHT_THRESHOLD ]; then
            switch_to_night
        fi
    else
        # 当前是黑夜模式，检查是否需要切换到白天模式
        if [ $daynight_value -lt $DAY_THRESHOLD ]; then
            switch_to_day
        fi
    fi

    # 等待指定时间后再次检查
    sleep $CHECK_INTERVAL
done
