# Dewbye 프로젝트 상태 및 TODO
**날짜**: 2025년 12월 1일
**상태**: Phase 1-3 완료, Phase 4 대기

---

## 완료된 작업

### 초기 설정 (11/30)
- [x] Git 저장소 초기화
- [x] GitHub 원격 저장소 연결 (`https://github.com/guyster323/Dewbye.git`)
- [x] 프로젝트 분석 완료 (TSX 파일 3개, MD 문서 3개)
- [x] Flutter 앱 개발 계획 수립

### Phase 1: 프로젝트 셋업 (12/1) ✅ 완료
- [x] Flutter 프로젝트 생성 (`flutter create dewbye`)
- [x] 패키지 의존성 설정 (pubspec.yaml)
- [x] 기본 폴더 구조 생성
- [x] 테마 시스템 (라이트/다크) - `lib/config/theme.dart`
- [x] 기본 네비게이션 구조 - 5개 화면 라우팅
- [x] 상수 및 설정 파일 - `lib/config/constants.dart`
- [x] Provider 상태 관리 구조 (Theme, Location, Analysis)
- [x] 기본 화면 구현 (Home, Location, Analysis, Graph, Settings)
- [x] Debug APK 빌드 성공

### Phase 2: UI 컴포넌트 (12/1) ✅ 완료
- [x] Glassmorphism 디자인 시스템 (`glassmorphism_container.dart`)
- [x] AppHeader 위젯 (다크모드 토글 애니메이션) (`header.dart`)
- [x] LocationInput 위젯 (`location_input.dart`)
- [x] 결로 애니메이션 구현 (`condensation_animation.dart`)
- [x] 배경 슬라이드쇼 (`background_slideshow.dart`)
- [x] HomeScreen 업데이트 (새 위젯 적용)

### Phase 3: 데이터 연동 (12/1) ✅ 완료
- [x] Open-Meteo API 통합 (글로벌) - `weather_api.dart`
  - 과거 기상 데이터 조회 (Archive API)
  - 현재 및 예보 데이터 조회 (Forecast API)
  - 위치 검색 (Geocoding API)
- [x] 기상청 API 통합 (한국) - `kma_api.dart`
  - 초단기 실황 조회
  - 초단기 예보 조회 (6시간)
  - 단기 예보 조회 (3일)
  - 위경도 → 격자 좌표 변환
- [x] GPS 위치 서비스 - `location_service.dart`
  - 권한 확인/요청
  - 현재 위치 가져오기
  - 위치 스트림
- [x] 주소 검색 (Geocoding) - Open-Meteo Geocoding
- [x] 데이터 캐싱 (Hive) - `cache_service.dart`
  - 날씨 데이터 캐시
  - 저장된 위치 관리
  - 앱 설정 저장
- [x] Provider에 서비스 통합
  - LocationProvider 업데이트
  - AnalysisProvider 업데이트

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
├── 251201_status_todo.md        # 이 파일
└── dewbye/                      # Flutter 프로젝트
    ├── android/
    ├── lib/
    │   ├── main.dart            # 앱 진입점
    │   ├── app.dart             # MaterialApp 설정
    │   ├── config/
    │   │   ├── theme.dart       # 라이트/다크 테마
    │   │   └── constants.dart   # 상수, enum 정의
    │   ├── providers/
    │   │   ├── theme_provider.dart
    │   │   ├── location_provider.dart   # ⭐ 서비스 통합
    │   │   └── analysis_provider.dart   # ⭐ API 연동
    │   ├── screens/
    │   │   ├── home_screen.dart         # ⭐ 새 위젯 적용
    │   │   ├── location_select_screen.dart  # ⭐ 검색 기능
    │   │   ├── analysis_screen.dart
    │   │   ├── graph_screen.dart
    │   │   └── settings_screen.dart     # ⭐ 캐시 관리
    │   ├── widgets/             # ⭐ Phase 2 완료
    │   │   ├── widgets.dart     # export 파일
    │   │   ├── glassmorphism_container.dart
    │   │   ├── header.dart
    │   │   ├── location_input.dart
    │   │   ├── condensation_animation.dart
    │   │   └── background_slideshow.dart
    │   ├── models/              # ⭐ Phase 3 완료
    │   │   ├── weather_data.dart
    │   │   └── location.dart
    │   ├── services/            # ⭐ Phase 3 완료
    │   │   ├── services.dart    # export 파일
    │   │   ├── weather_api.dart # Open-Meteo API
    │   │   ├── kma_api.dart     # 기상청 API
    │   │   ├── location_service.dart
    │   │   └── cache_service.dart
    │   └── utils/               # Phase 4에서 구현 예정
    ├── assets/
    │   ├── images/
    │   └── animations/
    └── pubspec.yaml
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

### Phase 4: 분석 엔진 강화
- [ ] HVAC 로직 취약 시간대 예측
- [ ] 기밀도별 습도 응답 예측
- [ ] 결로 발생 시점 예측 알고리즘
- [ ] 일별/주별 요약 리포트 생성

### Phase 5: 시각화 개선
- [ ] fl_chart 인터랙티브 그래프 개선
- [ ] 이벤트 타임라인 리스트
- [ ] 상세 분석 테이블
- [ ] 위험도 게이지 애니메이션

### Phase 6: 내보내기 & 마무리
- [ ] CSV 내보내기
- [ ] PDF 리포트 생성
- [ ] 알림 기능 (위험도 기준)
- [ ] 성능 최적화
- [ ] Play Store 배포 준비

---

## 구현된 기능 상세

### 테마 시스템
- Material 3 디자인 적용
- 라이트/다크 모드 전환 (애니메이션 포함)
- 위험도 색상 체계 (안전/주의/경고/위험)
- Hive를 통한 테마 설정 저장

### UI 컴포넌트
- Glassmorphism 디자인 (컨테이너, 버튼, 칩)
- 결로 위험도 애니메이션 (물방울 효과)
- 날씨 조건별 배경 그라데이션
- 위치 입력/검색 위젯

### 데이터 서비스
- Open-Meteo API (글로벌 기상 데이터)
  - Archive API: 과거 데이터 (최대 1년)
  - Forecast API: 예보 데이터 (7일)
  - Geocoding API: 위치 검색
- 기상청 API (한국 고정밀도)
  - 격자 좌표 변환 (Lambert Conformal)
  - 초단기/단기 예보
- 위치 서비스 (Geolocator)
- 캐시 시스템 (Hive)

### 분석 엔진
- Magnus 공식 기반 이슬점 계산
- 건물 기밀도(4단계) 기반 위험도 보정
- 권장 조치 자동 생성
- 일별 요약 통계

---

## 설치된 패키지

```yaml
dependencies:
  provider: ^6.1.1      # 상태 관리
  http: ^1.1.2          # 네트워킹
  dio: ^5.4.0
  geolocator: ^11.0.0   # 위치
  geocoding: ^2.2.0
  fl_chart: ^0.66.0     # 차트
  hive: ^2.2.3          # 로컬 저장
  hive_flutter: ^1.1.0
  glassmorphism_ui: ^0.3.0  # UI
  lottie: ^3.1.0
  shimmer: ^3.0.0
  csv: ^6.0.0           # 파일 생성
  pdf: ^3.10.8
  path_provider: ^2.1.2
  share_plus: ^7.2.2
  intl: ^0.19.0         # 유틸리티
```

---

## API 연동 정보

| API | 용도 | 엔드포인트 | 상태 |
|-----|------|-----------|------|
| **Open-Meteo Archive** | 글로벌 과거 기상 | `archive-api.open-meteo.com/v1/archive` | ✅ 완료 |
| **Open-Meteo Forecast** | 글로벌 예보 | `api.open-meteo.com/v1/forecast` | ✅ 완료 |
| **Open-Meteo Geocoding** | 위치 검색 | `geocoding-api.open-meteo.com/v1/search` | ✅ 완료 |
| **기상청 (KMA)** | 한국 고정밀도 | `apis.data.go.kr/1360000` | ✅ 완료 (API 키 필요) |

---

## Git 상태

- **로컬**: 초기화 완료
- **원격**: `https://github.com/guyster323/Dewbye.git`
- **최근 커밋**: Phase 2 완료
- **다음 커밋**: Phase 3 완료

---

## 빌드 정보

- **Debug APK**: `dewbye/build/app/outputs/flutter-apk/app-debug.apk`
- **Flutter 버전**: 최신 stable
- **Dart SDK**: ^3.9.2
- **빌드 시간**: ~12초

---

**마지막 업데이트**: 2025년 12월 1일 (Phase 3 완료)
