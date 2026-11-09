# BUILD A GOAT — Фаза 1 (заметки разработчика)

🇬🇧 English version: [README.md](README.md)

Нативная iOS-игра: собери идеального бойца MMA, забирая по одному атрибуту у случайных легенд UFC.

**Готово в Фазе 1:** архитектура, дизайн-система, навигация (Home → Fighter Builder → итог сборки), экран Fighter Builder с силуэтом, 10 слотами и оранжевыми линиями к зонам тела, движок случайного выбора с seed, выбор атрибутов, SPIN с анимацией барабана и хаптикой, адаптивная раскладка (iPhone — вертикально, iPad/широкий экран — три панели), 38 легенд во всех 12 дивизионах, тесты доменной логики.

## Запуск

Требуется **Xcode 16+** (Swift 6, iOS 17+).

1. Откройте `BuildAGoat.xcodeproj`.
2. Выберите схему **BuildAGoat** и симулятор (например, iPhone 16 Pro или iPad Pro — на iPad будет трёхпанельный вид).
3. ⌘R.

Если нужна подпись для реального устройства: Target → Signing & Capabilities → выберите свою Team.

Тесты домена: откройте `Packages/BuildAGoatKit/Package.swift` в Xcode и нажмите ⌘U, или в терминале:

```bash
cd Packages/BuildAGoatKit && swift test
```

Запасной вариант, если `.xcodeproj` не откроется: `brew install xcodegen && xcodegen` в корне (используется `project.yml`).

## Визуальный стиль

Палитра в духе бойцовских трансляций: чёрный фон `#09090A`, карточки `#161618`, основной красный `#D20A0A` (светлый `#FF3B3B`, тёмный `#7A0606`), белый `#F5F5F5`. Тир S отображается белой плашкой с красным свечением, A — красной, B — серебром, C — серым, D — тусклым чёрным. Все цвета собраны в `GoatTheme.swift` и `TierStyle.swift`. Логотип и фирменные элементы UFC не используются.

## Архитектура

```
BuildAGoat/
├── BuildAGoat.xcodeproj
├── BuildAGoat/                     ← app-таргет (composition root)
│   ├── BuildAGoatApp.swift         ← связывает Data → Presentation
│   └── Assets.xcassets
└── Packages/BuildAGoatKit/         ← весь код игры (SPM)
    ├── Sources/
    │   ├── GoatDomain/             ← чистый Swift, без SwiftUI
    │   │   ├── Models/             Fighter, FighterAttributes, FighterRecord, WeightClass,
    │   │   │                       FighterAttribute, Tier, AttributeSlot, AttributeSelection,
    │   │   │                       SpinResult, GameSession
    │   │   ├── Rating/             AttributeWeights (настраиваемые, сумма = 100%),
    │   │   │                       OverallRatingCalculator
    │   │   ├── Random/             SeededRandomNumberGenerator (SplitMix64)
    │   │   ├── Engine/             FighterSelectionEngine, GameEngine (правила игры)
    │   │   └── Repository/         протокол FighterRepository
    │   ├── GoatData/               ← SampleFighterCatalog, InMemoryFighterRepository
    │   └── GoatPresentation/       ← SwiftUI + @Observable view models
    │       ├── DesignSystem/       цвета, шрифты, стили тиров, панели
    │       ├── Components/         SpinButton, FighterPortrait, DivisionChip…
    │       ├── Silhouette/         векторный силуэт бойца + точки привязки атрибутов
    │       ├── Builder/            Fighter Builder: экран, VM, три панели, доска
    │       ├── Home/  Career/  Navigation/
    └── Tests/GoatDomainTests/      Swift Testing
```

Зависимости: `Presentation → Domain ← Data`. Presentation не знает о Data; конкретный репозиторий подставляет app-таргет. В Фазе 2 `InMemoryFighterRepository` заменяется на SwiftData-реализацию того же протокола, и UI менять не придётся.

## Ключевые игровые решения

- **Цикл:** `spin()` → `select(_:)` → `spin()`… Нельзя крутить, пока не выбран атрибут. За спин берётся один атрибут, но до следующего SPIN выбор можно переключить на любой другой свободный слот: это защита от случайных нажатий. Нажатие SPIN («LOCK IN & SPIN») фиксирует выбор навсегда. Последний, десятый, выбор можно менять до SIMULATE CAREER. Один и тот же боец может выпадать повторно.
- **Случайный выбор:** сначала равновероятно выбирается дивизион (из тех, где есть бойцы), затем боец внутри него. Порядок фиксирован, поэтому один и тот же seed всегда даёт одну и ту же последовательность. Генератор собственный (SplitMix64), чтобы последовательность не менялась между версиями Swift.
- **Общий рейтинг:** взвешенное среднее по весам из ТЗ плюс штраф за «дыры»: каждый атрибут ниже 70 снижает рейтинг пропорционально своему весу. В MMA слабые места находят. Пока слоты не заполнены, рейтинг помечен как PROVISIONAL.
- **Дивизион вашего бойца** определяется тем, у кого вы взяли SIZE. Это добавляет стратегии: размер тяжеловеса превращает бойца в тяжеловеса. Пригодится для симуляции в Фазе 3.
- **SIZE** оценивается относительно своего дивизиона (каркас, размах, сила), поэтому SIZE флайвейта не обязательно плохой выбор.
- Каждая `AttributeSelection` хранит `sourceFighterID`, имя, дивизион и номер спина.

## Данные — важно

Рейтинги атрибутов — **субъективные экспертные оценки** пика карьеры, а не официальные данные UFC. Рекорды указаны **приблизительно**; у действующих бойцов они меняются, их нужно сверить при сборке полной базы в Фазе 2. В приложении стоит дисклеймер. Портреты — заглушки-монограммы с флагом: фото бойцов требуют лицензии.

## Следующие фазы

- **Фаза 2:** расширенная база бойцов, SwiftData-персистентность `GameSession` (продолжение игры после перезапуска), уточнение рейтинга.
- **Фаза 3:** симуляция карьеры (модели `CareerSimulation`, `GOATRanking`, `FighterComparison`), Fighter DNA, GOAT-рейтинг. Сейчас на их месте экран итога сборки.
- **Фаза 4:** экран результата, карточка для Instagram Stories через `ImageRenderer` + `ShareLink`, финальная полировка.
