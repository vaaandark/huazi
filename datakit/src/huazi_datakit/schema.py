"""碑帖数据的模式定义。YAML 文件的唯一真相来源。"""

from __future__ import annotations

from enum import Enum
from typing import Literal

from pydantic import BaseModel, Field, field_validator


class Script(str, Enum):
    zhuan = "zhuan"
    li = "li"
    kai = "kai"
    xing = "xing"
    cao = "cao"


SCRIPT_LABEL = {
    "zhuan": "篆书",
    "li": "隶书",
    "kai": "楷书",
    "xing": "行书",
    "cao": "草书",
}


class Carrier(str, Enum):
    beike = "beike"        # 碑刻
    muzhi = "muzhi"        # 墓志
    moya = "moya"          # 摩崖
    zaoxiang = "zaoxiang"  # 造像
    ketie = "ketie"        # 刻帖
    moji = "moji"          # 墨迹
    xiejing = "xiejing"    # 写经


CARRIER_LABEL = {
    "beike": "碑刻",
    "muzhi": "墓志",
    "moya": "摩崖",
    "zaoxiang": "造像",
    "ketie": "刻帖",
    "moji": "墨迹",
    "xiejing": "写经",
}


class Source(BaseModel):
    name: str
    url: str | None = None
    license: str | None = None
    retrieved: str | None = None


class WorkImage(BaseModel):
    seq: int
    remote: str
    thumb: str | None = None
    width: int | None = None
    height: int | None = None
    license: str | None = None
    note: str | None = None


class Work(BaseModel):
    id: str = Field(pattern=r"^[a-z0-9][a-z0-9-]*$")
    title: str
    aliases: list[str] = Field(default_factory=list)
    author: str | None = None
    author_id: str | None = None
    writer: str | None = None
    carver: str | None = None
    dynasty: str | None = None
    era: str | None = None
    script: Script | None = None
    carrier: Carrier | None = None
    lines: int | None = None
    chars_per_line: int | None = None
    total_chars: int | None = None
    holder: str | None = None
    rubbing: str | None = None
    summary: str | None = None
    description: str | None = None
    transcription: str | None = None
    rights: str | None = None
    layout: str | None = None
    images: list[WorkImage] = Field(default_factory=list)
    sources: list[Source] = Field(default_factory=list)
    status: Literal["draft", "reviewed"] = "draft"
    notes: str | None = None

    @field_validator("title", "id")
    @classmethod
    def _not_blank(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("不能为空")
        return v.strip()

    def missing(self) -> list[str]:
        """返回缺失的关键字段，供 validate 用。"""
        required = ["author", "dynasty", "script", "carrier", "summary"]
        return [f for f in required if not getattr(self, f)]

    @property
    def image_count(self) -> int:
        return len(self.images)


class Person(BaseModel):
    id: str
    name: str
    dynasty: str | None = None
    birth: str | None = None
    death: str | None = None
    styles: list[Script] = Field(default_factory=list)
    bio: str | None = None
    sources: list[Source] = Field(default_factory=list)
