# Xuro

[English](README.md) · [中文说明](README_zh.md)

ไคลเอนต์ [ASMR.ONE](https://asmr.one) ที่สร้างด้วย Flutter ดีไซน์ทันสมัย ใช้งานลื่นไหล

## ภาพรวมโปรเจกต์

Xuro มุ่งมั่นมอบประสบการณ์ฟัง ASMR ที่ราบรื่นและสนุกสนาน พร้อมแอนิเมชันสวยงามและ UI ทันสมัย

## คุณสมบัติ

- เล่นเพลงเบื้องหลังได้เสถียร
- แอนิเมชันสวยและ UI เรียบง่าย
- แสดงซับไตเติ้ล/เนื้อเพลง รองรับนำเข้า VTT/LRC
- **แปลซับไตเติ้ลด้วย LLM** (OpenAI-compatible / OpenRouter) แสดงผลทีละบรรทัดแบบสตรีม
- จัดการเพลย์ลิสต์
- สำรวจหลายมิติ: แท็ก วงกลม นักพากย์
- รายการโปรด
- รองรับการแจ้งเตือน Android 13+
- หน้าต่างเนื้อเพลงลอย (Android)
- ระบบการตั้งค่าครบถ้วน
- แคชอัจฉริยะ (รูปภาพ ซับไตเติ้ล ไฟล์เสียง)
- จัดการแคชแบบรวมศูนย์
- ดาวน์โหลดสื่อสำหรับฟังออฟไลน์

## ความต้องการของระบบ

- Flutter 3.27.0+ (ใช้ FVM — ดู `.fvmrc`)
- Dart SDK >=3.2.3 <4.0.0
- Android: minSdk 21 / targetSdk 33
- Java 17

## เริ่มต้นใช้งาน

```bash
git clone https://github.com/yami-codes/Xuro.git
cd Xuro

fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter run
fvm flutter test
fvm flutter build apk --release
```

## โครงสร้างโปรเจกต์

```
lib/
├── core/                 # ฟังก์ชันหลัก (เสียง ซับไตเติ้ล ธีม แคช LLM แพลตฟอร์ม)
├── data/                 # ชั้นข้อมูล (API โมเดล repository)
├── presentation/         # ชั้นนำเสนอ (ViewModel)
├── screens/              # หน้าจอเต็ม
├── widgets/              # คอมโพเนนต์ UI ที่ใช้ซ้ำได้
└── common/               # ยูทิลิตี้และค่าคงที่
```

## แนวทางการพัฒนา

- [ขั้นตอนการพัฒนา (บังคับ)](docs/dev_workflow.md)
- [แนวทางการพัฒนา](docs/guidelines_en.md)
- [ติดตาม TODO](docs/todos/)

## การมีส่วนร่วม

โปรดอ่าน [ขั้นตอนการพัฒนา](docs/dev_workflow.md) และ [แนวทางการพัฒนา](docs/guidelines_en.md) ก่อนส่ง PR

## สัญญาอนุญาต

โปรเจกต์นี้ใช้สัญญา Creative Commons Attribution-NonCommercial-ShareAlike (CC BY-NC-SA) — ดูรายละเอียดใน [LICENSE](LICENSE)

ผู้เขียนต้นฉบับ: [asmroneapp](https://github.com/asmroneapp) | ที่เก็บต้นฉบับ: [Yuro](https://github.com/asmroneapp/Yuro)
