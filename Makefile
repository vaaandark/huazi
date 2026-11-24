.PHONY: help setup data views thumbs build run apk clean

help:
	@echo "huazi 构建入口"
	@echo "  make setup   安装 Python 依赖"
	@echo "  make data    从书格导入碑帖草稿（幂等）"
	@echo "  make views   补写核心名碑（欧颜柳等）"
	@echo "  make thumbs  下载缩略图"
	@echo "  make build   编译 SQLite 并同步到 app 资源"
	@echo "  make run     在本机跑 Linux 桌面版"
	@echo "  make apk     打 Android release 包"

setup:
	cd datakit && uv sync

data:
	cd datakit && uv run huazi-data import

views:
	python3 tool/seed_core_works.py

thumbs:
	cd datakit && uv run huazi-data thumbs --max-per-work 6

build:
	cd datakit && uv run huazi-data validate
	cd datakit && uv run huazi-data build
	cp build/huazi.sqlite app/assets/db/huazi.sqlite
	rm -rf app/assets/thumbs && mkdir -p app/assets/thumbs
	cp build/thumbs/*.webp app/assets/thumbs/ 2>/dev/null || true
	@echo "assets: $$(du -sh app/assets | cut -f1)"

run:
	cd app && GDK_BACKEND=x11 LIBGL_ALWAYS_SOFTWARE=1 flutter run -d linux

apk:
	cd app && flutter build apk --release --split-per-abi

clean:
	rm -rf build app/build app/assets/thumbs app/assets/db/*.sqlite
