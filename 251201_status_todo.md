# Dewbye 프로젝트 상태 및 TODO
**날짜**: 2025년 12월 1일
**상태**: Phase 1 완료, Phase 2 진행 중

---

## 완료된 작업

### 초기 설정 (11/30)
- [x] Git 저장소 초기화
- [x] GitHub 원격 저장소 연결 (`https://github.com/windo/Dewbye.git`)
- [x] 프로젝트 분석 완료 (TSX 파일 3개, MD 문서 3개)
- [x] Flutter 앱 개발 계획 수립

### 즉시 진행 항목 (12/1)
- [x] Flutter 프로젝트 생성 (`flutter create dewbye`)
- [x] 패키지 의존성 설정 (pubspec.yaml)
- [x] 기본 폴더 구조 생성

### Phase 1: 프로젝트 셋업 (12/1) ✅ 완료
- [x] 테마 시스템 (라이트/다크) - `lib/config/theme.dart`
- [x] 기본 네비게이션 구조 - 5개 화면 라우팅
- [x] 상수 및 설정 파일 - `lib/config/constants.dart`
- [x] Provider 상태 관리 구조 (Theme, Location, Analysis)
- [x] 기본 화면 구현 (Home, Location, Analysis, Graph, Settings)
- [x] Debug APK 빌드 성공

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
└── dewbye/                      # Flutter 프로젝트 ⭐ NEW
    ├── android/
    ├── lib/
    │   ├── main.dart            # 앱 진입점
    │   ├── app.dart             # MaterialApp 설정
    │   ├── config/
    │   │   ├── theme.dart       # 라이트/다크 테마
    │   │   └── constants.dart   # 상수, enum 정의
    │   ├── providers/
    │   │   ├── theme_provider.dart
    │   │   ├── location_provider.dart
    │   │   └── analysis_provider.dart
    │   ├── screens/
    │   │   ├── home_screen.dart
    │   │   ├── location_select_screen.dart
    │   │   ├── analysis_screen.dart
    │   │   ├── graph_screen.dart
    │   │   └── settings_screen.dart
    │   ├── widgets/             # Phase 2에서 구현 예정
    │   ├── models/              # Phase 3에서 구현 예정
    │   ├── services/            # Phase 3에서 구현 예정
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

### Phase 2: UI 컴포넌트 (진행 중)
- [ ] Glassmorphism 디자인 시스템
- [ ] Header 위젯 (다크모드 토글)
- [ ] LocationInput 위젯
- [ ] 결로 애니메이션 구현
- [ ] 배경 슬라이드쇼

### Phase 3: 데이터 연동
- [ ] Open-Meteo API 통합 (글로벌)
- [ ] 기상청 API 통합 (한국)
- [ ] GPS 위치 서비스
- [ ] 주소 검색 (Geocoding)
- [ ] 데이터 캐싱 (Hive/SQLite)

### Phase 4: 분석 엔진
- [ ] 절대습도/이슬점 계산 (기본 구현 완료)
- [ ] HVAC 로직 취약 시간대 예측
- [ ] 기밀도별 습도 응답 예측
- [ ] 결로 위험도 스코어 계산 (기본 구현 완료)
- [ ] 권장 조치 생성 (기본 구현 완료)

### Phase 5: 시각화
- [ ] fl_chart 온습도 그래프 (기본 구현 완료)
- [ ] 이벤트 타임라인 리스트
- [ ] 상세 분석 테이블
- [ ] 위험도 게이지

### Phase 6: 내보내기 & 마무리
- [ ] CSV 내보내기
- [ ] PDF 리포트 생성
- [ ] 로컬 저장 기능
- [ ] 성능 최적화

---

## 구현된 기능 상세

### 테마 시스템
- Material 3 디자인 적용
- 라이트/다크 모드 전환
- 위험도 색상 체계 (안전/주의/경고/위험)
- Hive를 통한 테마 설정 저장

### 분석 엔진 (기본)
- Magnus 공식 기반 이슬점 계산
- 건물 기밀도(4단계) 기반 위험도 보정
- 권장 조치 자동 생성

### 차트 (기본)
- fl_chart 기반 라인 차트
- 위험도/온습도/이슬점 3종 차트
- 터치 툴팁 지원

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
- **최근 커밋**: Phase 1 완료

---

## 빌드 정보

- **Debug APK**: `dewbye/build/app/outputs/flutter-apk/app-debug.apk`
- **Flutter 버전**: 최신 stable
- **Dart SDK**: ^3.9.2

---

**마지막 업데이트**: 2025년 12월 1일
