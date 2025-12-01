# Dewbye 프로젝트 상태 및 TODO
**날짜**: 2025년 11월 30일
**상태**: 초기 설정 완료, Flutter 개발 준비 단계

---

## 완료된 작업

- [x] Git 저장소 초기화
- [x] GitHub 원격 저장소 연결 (`https://github.com/windo/Dewbye.git`)
- [x] 프로젝트 분석 완료 (TSX 파일 3개, MD 문서 3개)
- [x] Flutter 앱 개발 계획 수립

---

## 현재 파일 구조

```
Dewbye/
├── app.tsx                      # 메인 화면 디자인 (Figma)
├── analyze.tsx                  # 분석 화면 디자인 (Figma)
├── graph.tsx                    # 그래프 화면 디자인 (Figma)
├── ESS_Guardian_Concept.md      # ESS 화재 위험 예측 개념 문서
├── HVAC_Logic_Global_Data.md    # HVAC 로직 및 글로벌 데이터 설계
├── Weather_HVAC_Analytics.md    # 기본 앱 설계 문서
└── 251130_status_todo.md        # 이 파일
```

---

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **앱 이름** | Dewbye (Weather-HVAC Analytics) |
| **목적** | 기상 데이터 기반 HVAC 운용 분석 및 결로/누전 위험 예측 |
| **플랫폼** | Android (Flutter 기반) |
| **타겟 사용자** | 건물 에너지 관리자, ESS 운영사, 주택 소유자 |

---

## 다음 단계 TODO

### 즉시 진행 필요
- [ ] Flutter 프로젝트 생성 (`flutter create dewbye`)
- [ ] 패키지 의존성 설정 (pubspec.yaml)
- [ ] 기본 폴더 구조 생성

### Phase 1: 프로젝트 셋업 (1주)
- [ ] 테마 시스템 (라이트/다크)
- [ ] 기본 네비게이션 구조
- [ ] 상수 및 설정 파일

### Phase 2: UI 컴포넌트 (1주)
- [ ] Glassmorphism 디자인 시스템
- [ ] Header 위젯 (다크모드 토글)
- [ ] LocationInput 위젯
- [ ] 결로 애니메이션 구현
- [ ] 배경 슬라이드쇼

### Phase 3: 데이터 연동 (1주)
- [ ] Open-Meteo API 통합 (글로벌)
- [ ] 기상청 API 통합 (한국)
- [ ] GPS 위치 서비스
- [ ] 주소 검색 (Geocoding)
- [ ] 데이터 캐싱 (Hive/SQLite)

### Phase 4: 분석 엔진 (1주)
- [ ] 절대습도/이슬점 계산
- [ ] HVAC 로직 취약 시간간 예측측
- [ ] 기밀도별 습도 응답 예측
- [ ] 결로 위험도 스코어 계산
- [ ] 권장 조치 생성

### Phase 5: 시각화 (1주)
- [ ] fl_chart 온습도 그래프
- [ ] 이벤트 타임라인 리스트
- [ ] 상세 분석 테이블
- [ ] 위험도 게이지

### Phase 6: 내보내기 & 마무리 (3일)
- [ ] CSV 내보내기
- [ ] PDF 리포트 생성
- [ ] 로컬 저장 기능
- [ ] 성능 최적화

---

## Flutter 프로젝트 구조 (예정)

```
dewbye/
├── android/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── config/
│   │   ├── theme.dart
│   │   └── constants.dart
│   ├── models/
│   │   ├── weather_data.dart
│   │   ├── hvac_event.dart
│   │   ├── location.dart
│   │   └── analysis_result.dart
│   ├── services/
│   │   ├── weather_api.dart
│   │   ├── kma_api.dart
│   │   ├── location_service.dart
│   │   └── analytics_engine.dart
│   ├── providers/
│   │   ├── theme_provider.dart
│   │   ├── location_provider.dart
│   │   └── analysis_provider.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── location_select_screen.dart
│   │   ├── building_type_screen.dart
│   │   ├── analysis_screen.dart
│   │   └── detail_screen.dart
│   ├── widgets/
│   │   ├── header.dart
│   │   ├── location_input.dart
│   │   ├── vulnerability_chart.dart
│   │   ├── condensation_animation.dart
│   │   ├── background_slideshow.dart
│   │   ├── event_timeline.dart
│   │   └── glassmorphism_container.dart
│   └── utils/
│       ├── hvac_calculator.dart
│       ├── date_formatter.dart
│       └── export_helper.dart
├── assets/
│   ├── images/
│   └── animations/
└── pubspec.yaml
```

---

## 필수 패키지

```yaml
dependencies:
  flutter:
    sdk: flutter

  # 상태 관리
  provider: ^6.1.1

  # 네트워킹
  http: ^1.1.2
  dio: ^5.4.0

  # 위치
  geolocator: ^11.0.0
  geocoding: ^2.2.0
  google_maps_flutter: ^2.5.3

  # 차트
  fl_chart: ^0.66.0

  # 로컬 저장
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  sqflite: ^2.3.2

  # UI
  glassmorphism_ui: ^0.3.0
  lottie: ^3.1.0
  shimmer: ^3.0.0

  # 파일 생성
  csv: ^6.0.0
  pdf: ^3.10.8
  path_provider: ^2.1.2
  share_plus: ^7.2.2

  # 유틸리티
  intl: ^0.19.0
```

---

## API 연동 정보

| API | 용도 | 엔드포인트 |
|-----|------|-----------|
| **Open-Meteo Archive** | 글로벌 과거 기상 | `archive-api.open-meteo.com/v1/archive` |
| **Open-Meteo Geocoding** | 위치 검색 | `geocoding-api.open-meteo.com/v1/search` |
| **기상청 (KMA)** | 한국 고정밀도 | `apis.data.go.kr/1360000` |

---

## 참고 문서

1. **Weather_HVAC_Analytics.md** - 기본 앱 설계, 비즈니스 모델
2. **HVAC_Logic_Global_Data.md** - HVAC 로직, 분석 알고리즘, Dart 코드 예시
3. **ESS_Guardian_Concept.md** - ESS 특화 버전 개념 (추후 고려)

---

## Git 상태

- **로컬**: 초기화 완료
- **원격**: `https://github.com/windo/Dewbye.git` 연결됨
- **첫 커밋**: 아직 안함 (다음 세션에서 진행)

---

## 다음 세션 시작 시

```bash
# 현재 상태 확인
cd C:\Users\windo\Dewbye
git status

# Flutter 프로젝트 생성
flutter create --org com.dewbye dewbye

# 또는 현재 폴더에서 Flutter 초기화
flutter create .
```

---

**마지막 업데이트**: 2025년 11월 30일
