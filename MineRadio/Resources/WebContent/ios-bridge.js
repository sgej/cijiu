/**
 * iOS Native Bridge Adapter
 * 
 * 这个文件提供了与Android版本兼容的JS桥接接口，
 * 使得原始的Web代码可以在iOS平台上运行。
 */

(function() {
    'use strict';

    // 检查是否在iOS环境中
    var isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) || 
                (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);

    if (!isIOS && !window.webkit) {
        console.log('非iOS环境，跳过桥接初始化');
        return;
    }

    console.log('iOS Native Bridge 初始化中...');

    // 创建Android兼容对象
    if (!window.Android) {
        window.Android = {};
    }

    // 消息队列，用于在原生环境准备好之前缓存消息
    var messageQueue = [];
    var isNativeReady = false;

    // 消息ID计数器
    var messageId = 0;

    // 回调函数映射
    var callbacks = {};

    // 发送消息到原生
    function postMessage(action, data, callback) {
        var message = {
            id: ++messageId,
            action: action,
            data: data || {}
        };

        // 如果有回调，保存起来
        if (callback) {
            callbacks[message.id] = callback;
        }

        // 如果原生还没准备好，加入队列
        if (!isNativeReady) {
            messageQueue.push(message);
            return;
        }

        // 发送消息
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.nativeBridge) {
            window.webkit.messageHandlers.nativeBridge.postMessage(message);
        }
    }

    // 处理原生回调
    function handleNativeCallback(messageId, result) {
        var callback = callbacks[messageId];
        if (callback) {
            callback(result);
            delete callbacks[messageId];
        }
    }

    // 原生环境准备就绪
    window.__onNativeReady = function(info) {
        console.log('原生环境已就绪:', info);
        isNativeReady = true;

        // 发送队列中的消息
        while (messageQueue.length > 0) {
            var message = messageQueue.shift();
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.nativeBridge) {
                window.webkit.messageHandlers.nativeBridge.postMessage(message);
            }
        }

        // 触发自定义事件
        var event = new CustomEvent('nativeReady', { detail: info });
        window.dispatchEvent(event);
    };

    // 原生事件处理
    window.__nativeEvent = function(eventName, data) {
        console.log('收到原生事件:', eventName, data);

        // 根据事件类型调用对应的处理函数
        switch (eventName) {
            case 'playStateChanged':
                if (typeof window._onPlayStateChanged === 'function') {
                    window._onPlayStateChanged(data);
                }
                break;
            case 'playProgressChanged':
                if (typeof window._onPlayProgressChanged === 'function') {
                    window._onPlayProgressChanged(data);
                }
                break;
            case 'currentSongChanged':
                if (typeof window._onCurrentSongChanged === 'function') {
                    window._onCurrentSongChanged(data);
                }
                break;
            case 'localFilesSelected':
                if (typeof window._onLocalFilesSelected === 'function') {
                    window._onLocalFilesSelected(data);
                }
                // 兼容旧接口
                if (typeof window._onLocalSongImported === 'function') {
                    data.files.forEach(function(file) {
                        window._onLocalSongImported(file);
                    });
                }
                break;
            case 'backgroundImageSelected':
                if (typeof window._onBackgroundImageSelected === 'function') {
                    window._onBackgroundImageSelected(data);
                }
                break;
            case 'handGestureDetected':
                if (typeof window._processNativeHandFrame === 'function') {
                    window._processNativeHandFrame(data);
                }
                break;
            case 'deviceInfo':
                if (typeof window._onDeviceInfo === 'function') {
                    window._onDeviceInfo(data);
                }
                break;
            default:
                // 触发自定义事件
                var event = new CustomEvent('native:' + eventName, { detail: data });
                window.dispatchEvent(event);
        }
    };

    // ========== 音乐播放相关接口 ==========

    // 播放音乐
    window.Android.playMusic = function(songInfo) {
        postMessage('playMusic', songInfo);
    };

    // 暂停音乐
    window.Android.pauseMusic = function() {
        postMessage('pauseMusic');
    };

    // 继续播放
    window.Android.resumeMusic = function() {
        postMessage('resumeMusic');
    };

    // 跳转到指定时间
    window.Android.seekTo = function(time) {
        postMessage('seekTo', { time: time });
    };

    // 设置音量
    window.Android.setVolume = function(volume) {
        postMessage('setVolume', { volume: volume });
    };

    // ========== 本地音乐相关接口 ==========

    // 导入本地音乐
    window.Android.importLocalMusic = function() {
        postMessage('importLocalMusic');
    };

    // 添加本地歌曲
    window.__addLocalSongWithCachedFile = function(filePath, fileName) {
        // iOS版本直接返回文件路径
        return filePath;
    };

    // ========== 背景图片相关接口 ==========

    // 选择背景图片
    window.Android.pickBackgroundImage = function() {
        postMessage('pickBackgroundImage');
    };

    // ========== 手势识别相关接口 ==========

    // 启动手势识别
    window.Android.startHandGesture = function() {
        postMessage('startHandGesture');
    };

    // 停止手势识别
    window.Android.stopHandGesture = function() {
        postMessage('stopHandGesture');
    };

    // ========== 设备信息相关接口 ==========

    // 获取设备信息
    window.Android.getDeviceInfo = function() {
        postMessage('getDeviceInfo');
    };

    // ========== 其他接口 ==========

    // 打开URL
    window.Android.openURL = function(url) {
        postMessage('openURL', { url: url });
    };

    // 保持屏幕常亮
    window.Android.keepScreenOn = function(enable) {
        // iOS通过其他方式实现，这里暂时留空
        console.log('保持屏幕常亮:', enable);
    };

    // 显示Toast
    window.Android.showToast = function(message) {
        // iOS可以用自定义实现，这里暂时用console
        console.log('Toast:', message);
    };

    // 获取缓存目录
    window.Android.getCacheDir = function() {
        // 返回一个虚拟路径，实际通过URL访问
        return '/cache';
    };

    // 获取文件目录
    window.Android.getFilesDir = function() {
        return '/files';
    };

    // ========== 平台信息 ==========

    // 平台标识
    window.__platform = 'ios';
    window.__platformVersion = '1.1.4';

    // 检查是否支持某个功能
    window.Android.hasFeature = function(feature) {
        var features = {
            localMusic: true,
            handGesture: true,
            backgroundPlay: true,
            desktopLyrics: false,
            liveWallpaper: false,
            equalizer: false
        };
        return features[feature] || false;
    };

    console.log('iOS Native Bridge 初始化完成');

})();
