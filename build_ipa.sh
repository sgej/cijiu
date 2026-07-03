#!/bin/bash
#
# MineRadio iOS 自动打包脚本
# 功能：自动编译、归档、导出IPA
# 使用方法：./build_ipa.sh [development|ad-hoc|app-store|enterprise]
#

set -e

# ==================== 配置项 ====================

# 项目名称
PROJECT_NAME="MineRadio"

# 项目文件路径
PROJECT_FILE="MineRadio.xcodeproj"

# Scheme名称
SCHEME="MineRadio"

# 配置类型 (Debug/Release)
CONFIGURATION="Release"

# 导出方式 (development/ad-hoc/app-store/enterprise)
EXPORT_METHOD="${1:-development}"

# 输出目录
OUTPUT_DIR="./build"

# 归档文件路径
ARCHIVE_PATH="${OUTPUT_DIR}/${PROJECT_NAME}.xcarchive"

# IPA导出路径
EXPORT_PATH="${OUTPUT_DIR}/ipa"

# 导出选项plist文件
EXPORT_OPTIONS_PLIST="${OUTPUT_DIR}/exportOptions.plist"

# ==================== 颜色定义 ====================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==================== 函数定义 ====================

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ==================== 检查环境 ====================

check_environment() {
    print_info "检查打包环境..."
    
    # 检查是否在macOS上运行
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "此脚本只能在 macOS 上运行"
        print_error "当前系统: $OSTYPE"
        exit 1
    }
    
    # 检查Xcode是否安装
    if ! command -v xcodebuild &> /dev/null; then
        print_error "未找到 Xcode 命令行工具"
        print_info "请安装 Xcode 并运行: xcode-select --install"
        exit 1
    fi
    
    # 检查Xcode版本
    XCODE_VERSION=$(xcodebuild -version | head -1 | awk '{print $2}')
    print_info "Xcode 版本: $XCODE_VERSION"
    
    # 检查项目文件是否存在
    if [ ! -f "$PROJECT_FILE" ]; then
        print_error "找不到项目文件: $PROJECT_FILE"
        exit 1
    }
    
    print_success "环境检查通过"
}

# ==================== 生成导出选项plist ====================

generate_export_options() {
    print_info "生成导出选项配置 (${EXPORT_METHOD})..."
    
    mkdir -p "$OUTPUT_DIR"
    
    # 根据导出方式生成不同的配置
    case "$EXPORT_METHOD" in
        development)
            METHOD="development"
            SIGNING_STYLE="automatic"
            ;;
        ad-hoc)
            METHOD="ad-hoc"
            SIGNING_STYLE="automatic"
            ;;
        app-store)
            METHOD="app-store"
            SIGNING_STYLE="automatic"
            ;;
        enterprise)
            METHOD="enterprise"
            SIGNING_STYLE="automatic"
            ;;
        *)
            print_error "不支持的导出方式: $EXPORT_METHOD"
            print_info "支持的方式: development, ad-hoc, app-store, enterprise"
            exit 1
            ;;
    esac
    
    cat > "$EXPORT_OPTIONS_PLIST" << PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>${METHOD}</string>
    <key>signingStyle</key>
    <string>${SIGNING_STYLE}</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>teamID</key>
    <string></string>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
PLIST_EOF
    
    print_success "导出选项配置已生成: $EXPORT_OPTIONS_PLIST"
}

# ==================== 清理旧的构建产物 ====================

clean_build() {
    print_info "清理旧的构建产物..."
    
    if [ -d "$OUTPUT_DIR" ]; then
        rm -rf "$OUTPUT_DIR"
        print_info "已清理: $OUTPUT_DIR"
    fi
    
    # 清理Xcode缓存
    if command -v xcodebuild &> /dev/null; then
        xcodebuild clean \
            -project "$PROJECT_FILE" \
            -scheme "$SCHEME" \
            -configuration "$CONFIGURATION" \
            -quiet 2>/dev/null || true
    fi
    
    print_success "清理完成"
}

# ==================== 编译并归档 ====================

archive_project() {
    print_info "开始编译并归档项目..."
    print_info "Scheme: $SCHEME"
    print_info "Configuration: $CONFIGURATION"
    
    xcodebuild archive \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -archivePath "$ARCHIVE_PATH" \
        -destination "generic/platform=iOS" \
        -quiet
    
    if [ $? -eq 0 ]; then
        print_success "归档成功: $ARCHIVE_PATH"
    else
        print_error "归档失败"
        exit 1
    fi
}

# ==================== 导出IPA ====================

export_ipa() {
    print_info "开始导出 IPA 文件..."
    print_info "导出方式: $EXPORT_METHOD"
    
    mkdir -p "$EXPORT_PATH"
    
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
        -quiet
    
    if [ $? -eq 0 ]; then
        IPA_FILE=$(find "$EXPORT_PATH" -name "*.ipa" | head -1)
        if [ -n "$IPA_FILE" ]; then
            IPA_SIZE=$(du -h "$IPA_FILE" | awk '{print $1}')
            print_success "IPA 导出成功: $IPA_FILE ($IPA_SIZE)"
        else
            print_warning "IPA 导出完成，但未找到 IPA 文件"
        fi
    else
        print_error "IPA 导出失败"
        print_info "请检查签名配置和证书"
        exit 1
    fi
}

# ==================== 显示结果 ====================

show_results() {
    echo ""
    echo "==================== 打包结果 ===================="
    echo ""
    
    if [ -d "$ARCHIVE_PATH" ]; then
        ARCHIVE_SIZE=$(du -sh "$ARCHIVE_PATH" | awk '{print $1}')
        echo "📦 归档文件: $ARCHIVE_PATH ($ARCHIVE_SIZE)"
    fi
    
    IPA_FILE=$(find "$EXPORT_PATH" -name "*.ipa" | head -1 2>/dev/null || echo "")
    if [ -n "$IPA_FILE" ] && [ -f "$IPA_FILE" ]; then
        IPA_SIZE=$(du -h "$IPA_FILE" | awk '{print $1}')
        echo "📱 IPA 文件: $IPA_FILE ($IPA_SIZE)"
    fi
    
    echo ""
    echo "导出方式: $EXPORT_METHOD"
    echo "配置类型: $CONFIGURATION"
    echo ""
    echo "=================================================="
    echo ""
    
    print_success "打包完成！"
}

# ==================== 主流程 ====================

main() {
    echo ""
    echo "=========================================="
    echo "  MineRadio iOS 自动打包工具"
    echo "=========================================="
    echo ""
    
    # 切换到脚本所在目录
    cd "$(dirname "$0")"
    
    check_environment
    generate_export_options
    clean_build
    archive_project
    export_ipa
    show_results
}

main "$@"
