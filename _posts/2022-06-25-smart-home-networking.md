---
layout: post
title: 智慧家庭 - 總心得
categories: [smarthome]
---

稍微寫幾篇智慧家庭的架設心得。

# 網路

網路穩定度應該屬於智慧家庭的重中之重，大部分裝置都會透過 Wi-Fi 連線，在同一個網段內連線溝通。

因此家中網路品質就是不會常常讓裝置離線的重要因素。

主要的 gateway 我還是用原本的 J1900 控制，並且把 Hinet ATU-R 的 Wi-Fi 功能關掉，

所有連線都經過我的 gateway ，這樣我就可以替每個裝置設定 DHCP static lease 並且把 lease time 改成七天。


針對家裡訊號涵蓋較弱的區域我又另外買了一台小米的訊號放大器，不過他是連上原本的 Wi-Fi 後又自己新增一組 SSID，

如果改成 AP 模式就可以把 gateway 的角色交還給既有的 J1900，小米只負責當個無線存取點，也可以共用 SSID。

總共兩台 AP 提供 Wi-Fi 2.4G+5G 訊號，共用同一個 SSID。


上層的軟體控制則是買了一台 i3-6300T 的迷你電腦安裝 hass 來當所有裝置的中央控制系統。

幾乎所有智慧家庭配件都可以在 hass 上面找到 integration 來進行接入。

因此不需要太擔心某個配件是不是支援 homekit，只要是 Wi-Fi 連線類型的裝置理論上就可以藉由 hass 控制。

安裝 hass 的 homekit integration 之後就可以在 `ios家庭` 上面把 hass 當成橋接器新增到家庭裡，

這時候你在 hass 裡面的所有配件都會跟著加進去，我不想讓 `ios家庭` 可以控制我的自動化要不要開啟，所以這邊我都排除掉了。

configuration.yaml

```
homekit:
  - filter:
      exclude_entity_globs:
        - automation.*
    name: Real HASS Bridge
    port: 21069
```

# 電力監控

用電量的監控在智慧家庭裡面是一個比較冷門的選項，不過都打算要進行打造了，

監控家裡用電量了解花費也是蠻有趣的，可以知道使用一項電器一個月到底佔多少花費，

比如說電腦就意外的其實跟冷氣的耗電量差不多，雖然只吃150w-200w，但是開啟時間長，吃電也多

我目前用的是 emporia vue 2 + emporia smart plug 的整套方案，

從配電盤掛上 CT 之後可以量測總用電量(一次側)和每個迴路的個別用電量(二次側)

如果迴路屬於多個插座共用類型的，這時候在插座接上 smart plug 就可以整合上去分辨出來是哪個插座用電，

而不只是知道某個迴路用電量很高，不過他建議 smart plug 長時間用不要超過 10A，所以電器的部分沒有特別做個別測量，

雖然仿間有很多廠商都有 smart plug 的產品，但要能完整的做電力監控也只能買全家餐了，畢竟是在他們的 APP 內做的整合。

由於台灣用電是 110V ，而原本設計是給 120V 使用，所以在設定時要記得填乘數是 0.92(110V) / 1.84(220V)

將 emporia 接入 hass 之後我唯一用到自動化的部分是設定除濕機在開啟四個小時後自動關閉，放在浴室旁邊洗澡後加快乾燥用。

電器櫃的部分則是用 TP-link 的那款六插延長線，可以做到基本的開關但用電量就沒有那麼詳細了，

使用上要自己算清楚延長線負載不要超過1650w，基本上就是一個延長線上面一次只能用一個烹飪用電器

automations.yaml

```
- id: '1655647325793'
  alias: 自動關閉除濕機
  description: ''
  trigger:
  - platform: state
    entity_id:
    - switch.switch_xi_lian_pen_pang_bian
    to: 'on'
    for:
      hours: 4
      minutes: 0
      seconds: 0
  condition: []
  action:
  - service: switch.turn_off
    data: {}
    target:
      entity_id: switch.switch_xi_lian_pen_pang_bian
  mode: single
```

# 燈光控制

燈光這塊主要就是控制照明，因為我沒有玩炫砲的七彩燈光搞電競夜店風的想法，

就是買米家吸頂燈有個基本的亮度/色溫調整，我買的是台版米家，

但後來就知道根本沒差，因為都是取得吸頂燈的 IP 和 token 後接入 hass 進行控制，

不太有打開米家APP的需求，也不會打開小愛同學控制它。

因為我想要類似flux的功能隨著日出日落自動調整亮度/色溫，我只想要控制燈光開關，

所以裝了 `circadian_lighting` integration 來自動調整。

configuration.yaml

```
circadian_lighting:
  sunset_offset: "01:00:00"
  min_colortemp: 2700
  max_colortemp: 6000
  interval: 30

switch:
  - platform: circadian_lighting
    sleep_entity: input_boolean.circadian_sleep_switch
    sleep_state: "on"
    disable_entity: input_boolean.circadian_disable_switch
    disable_state: "on"
    max_brightness: 75
    min_brightness: 10
    lights_ct:
      - light.gong_zuo_shi_xi_ding_deng
      - light.ke_ting_nei_deng
      - light.ke_ting_wai_deng
      - light.wo_shi_nei_deng
      - light.wo_shi_wai_deng
```

automation.yaml

```
- id: f644e2424d584141a62053931ce28c14
  alias: 臥室夜燈自動化開
  trigger:
  - platform: state
    entity_id: input_boolean.wo_shi_nightlight
    to: 'on'
  action:
  - service: miio_yeelink.send_command
    data:
      entity_id: light.wo_shi_nei_deng
      method: set_ps
      params:
      - nightlight
      - on|99
  - service: miio_yeelink.send_command
    data:
      entity_id: light.wo_shi_wai_deng
      method: set_ps
      params:
      - nightlight
      - on|99
- id: 114212d65b354cd4a352cbd144481b7c
  alias: 客廳夜燈自動化開
  trigger:
  - platform: state
    entity_id: input_boolean.ke_ting_nightlight
    to: 'on'
  action:
  - service: miio_yeelink.send_command
    data:
      entity_id: light.ke_ting_nei_deng
      method: set_ps
      params:
      - nightlight
      - on|99
```

這樣我只需要用 `ios家庭` 設定各種開關的情境即可，

比如睡前我就會用夜燈開關 (input_boolean) 把吸頂燈的月光模式打開，並且把 flux 停止開關也打開

讓 `circadian_lighting` 不會再幫我調整亮度，

每天清晨則設定自動關掉所有燈光和 flux 停止開關，使其復位，這樣早上開燈後它又能繼續進行自動調整

其他就是配合各種情境開啟落地燈，開啟展示櫃燈光... 可以直接設定在 `ios家庭`

# 家庭中樞

因為 `ios家庭` 需要一個中樞進行自動化操作

這部分也很簡單就是買幾個 HomePod mini 和 Apple TV 擺著就搞定

順便讓它做一些播放 podcast 或讓我到處都能喊 hey siri 的任務

# 空氣品質監控

我買的是青萍空氣檢測儀，從大陸買的所以需要陸板米家才能加入裝置，

基本上就把地區改成中國大陸，加入裝置完成後一樣把 IP 和 token 弄出來就可以加入到 hass 裡面了

抓到讀數之後就可以連動空調系統或是警告開關窗戶/空氣清淨機之類的

configuration.yaml

<!-- {% raw %} -->
```
sensor:
  - platform: template
    sensors:
      workroom_humidity:
        friendly_name: "工作室濕度"
        unit_of_measurement: "%"
        value_template: "{{ state_attr('air_quality.cgllc_airmonitor_s1', 'humidity') }}"
      workroom_temperature:
        friendly_name: "工作室溫度"
        unit_of_measurement: "°C"
        value_template: "{{ state_attr('air_quality.cgllc_airmonitor_s1', 'temperature') }}"
      workroom_co2:
        friendly_name: "工作室CO2"
        unit_of_measurement: "ppm"
        value_template: "{{ state_attr('air_quality.cgllc_airmonitor_s1', 'carbon_dioxide') }}"
      workroom_tvoc:
        friendly_name: "工作室TVOC"
        unit_of_measurement: "ppm"
        value_template: "{{ state_attr('air_quality.cgllc_airmonitor_s1', 'total_volatile_organic_compounds')|float / 1000 }}"
      workroom_pm25:
        friendly_name: "工作室pm2.5"
        unit_of_measurement: "ug/m3"
        value_template: "{{ state_attr('air_quality.cgllc_airmonitor_s1', 'particulate_matter_2_5') }}"
```
<!-- {% endraw %} -->
