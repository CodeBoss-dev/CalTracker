# CalTracker — Calorie & Nutrition Tracker

A native iOS app built with SwiftUI for tracking daily calories, macros, and weight. Features a curated Indian food database, rotating meal plans, smart suggestions, and detailed progress analytics.

---

## Features

- **Meal plan logging** — browse a weekly rotating menu and log entire meals in seconds
- **Indian food database** — 205+ dishes with culturally accurate serving sizes ("1 chapati", "1 katori dal")
- **Smart suggestions** — recommendations from today's menu to help hit your macro targets
- **Dashboard** — animated calorie ring, macro breakdown, per-meal summaries
- **Progress tracking** — weight log, 7-day calorie chart, 30-day averages, streak counter
- **Goal editor** — customise calorie and macro targets with a live macro balance bar
- **Full auth flow** — sign up, sign in, onboarding with BMR/TDEE calculation
- **Dark mode** — full support throughout

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 17+) |
| Architecture | MVVM |
| Backend | Supabase (PostgreSQL + Auth + RLS) |
| Charts | Swift Charts (built-in) |
| External dependency | `supabase-swift` via SPM |

---

## Project Structure

```
CalTracker/
├── App/
│   ├── CalTrackerApp.swift        # Entry point, RootView routing, SplashView
│   └── ContentView.swift          # 5-tab navigation
├── Models/
│   ├── UserProfile.swift          # UserProfile, UserGoals + enums
│   ├── Food.swift                 # Food model with macros
│   ├── FoodLogEntry.swift         # Log entry with computed totals
│   ├── MessMenu.swift             # Menu entry models (Supabase + local)
│   └── WeightEntry.swift          # Weight log entry
├── Services/
│   ├── SupabaseManager.swift      # Supabase client singleton
│   ├── AuthService.swift          # Sign up / sign in / onboarding
│   ├── FoodService.swift          # Search foods (Supabase + local fallback)
│   ├── FoodLogService.swift       # Log/delete entries, UserDefaults persistence
│   ├── MessMenuService.swift      # Load & cache meal plan JSON
│   ├── GoalsService.swift         # Persist + sync calorie/macro targets
│   ├── WeightLogService.swift     # Weight log CRUD
│   └── SuggestionEngine.swift     # Pure stateless suggestion logic
├── ViewModels/
│   ├── FoodLogViewModel.swift     # Today's log state, macro totals
│   ├── DashboardViewModel.swift   # Greeting, suggestion text
│   ├── MessMenuViewModel.swift    # Weekly menu browsing state
│   ├── ProgressViewModel.swift    # Streak, trends, weight change
│   └── SuggestionViewModel.swift  # Wires SuggestionEngine to the view
├── Views/
│   ├── Auth/                      # Login, SignUp, Onboarding
│   ├── Dashboard/                 # CalorieRing, MacroBars, MealCards, Suggestions
│   ├── Logging/                   # FoodSearch, FoodDetail, MealLog, MenuLog
│   ├── MessMenu/                  # WeeklyMenu, MenuConfig
│   ├── Progress/                  # Charts, WeightEntry, Streaks
│   ├── Profile/                   # Profile, GoalEditor
│   └── Components/                # ServingStepperView
├── Core/
│   ├── Theme/AppTheme.swift       # Spacing + radius tokens
│   ├── Extensions/ColorExtension.swift  # Color(hex:) + app color palette
│   └── Utilities/
│       ├── WeekResolver.swift     # Rotating menu cycle calculator
│       └── NutritionCalculator.swift    # BMR, TDEE, macro targets
└── Resources/
    ├── IndianFoodSeed.json        # 205 Indian dishes
    ├── MessMenuWeek1.json         # Menu plan week 1
    ├── MessMenuWeek2.json         # Menu plan week 2
    └── MessMenuWeek3.json         # Menu plan week 3
```

---

## Getting Started

### Prerequisites

- Xcode 15+
- iOS 17 simulator or device
- A free [Supabase](https://supabase.com) account

### 1. Clone the repo

```bash
git clone https://github.com/<your-username>/CalTracker.git
cd CalTracker
```

### 2. Set up Supabase

1. Create a new project on [supabase.com](https://supabase.com)
2. Go to **Project Settings → API** and copy your **Project URL** and **anon public key**
3. Open [Services/SupabaseManager.swift](Services/SupabaseManager.swift) and replace the placeholders:

```swift
private let supabaseURL = "https://your-project-id.supabase.co"
private let supabaseAnonKey = "your-anon-key-here"
```

4. In the Supabase **SQL Editor**, run the full schema from the section below to create all tables and RLS policies.

### 3. Open in Xcode

1. Open (or create) the `CalTrackerApp.xcodeproj` in Xcode
2. Add the SPM package: **File → Add Package Dependencies** → `https://github.com/supabase/supabase-swift`
3. Drag all `.swift` files into their respective Xcode groups and add them to the `CalTracker` target
4. Press `Cmd+R` to build and run

> **Note:** `.swift` source files are managed in this repo. The `.xcodeproj` file is not committed — you create it once in Xcode (Product Name: `CalTracker`, Interface: SwiftUI, Language: Swift, Minimum Deployment: iOS 17.0).

---

## Supabase Schema

Run this in **Supabase Dashboard → SQL Editor**:

```sql
-- Users table
create table public.users (
  id uuid references auth.users(id) on delete cascade primary key,
  name text not null,
  height_cm double precision not null,
  weight_kg double precision not null,
  age integer not null,
  activity_level text not null,
  goal text not null,
  created_at timestamptz default now()
);
alter table public.users enable row level security;
create policy "Users can read/write own profile" on public.users
  for all using (auth.uid() = id);

-- User goals
create table public.user_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade not null,
  daily_calories integer not null,
  protein_target integer not null,
  carbs_target integer not null,
  fat_target integer not null,
  updated_at timestamptz default now()
);
alter table public.user_goals enable row level security;
create policy "Users can read/write own goals" on public.user_goals
  for all using (auth.uid() = user_id);

-- Foods catalog
create table public.foods (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  calories_per_serving double precision not null,
  protein double precision not null default 0,
  carbs double precision not null default 0,
  fat double precision not null default 0,
  serving_unit text not null,
  serving_size double precision not null default 1,
  category text not null,
  is_custom boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);
alter table public.foods enable row level security;
create policy "All users can read global foods" on public.foods
  for select using (is_custom = false or auth.uid() = created_by);
create policy "Users can insert their own custom foods" on public.foods
  for insert with check (auth.uid() = created_by);
create policy "Users can update their own custom foods" on public.foods
  for update using (auth.uid() = created_by);

-- Food log
create table public.food_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  food_id uuid references public.foods(id) not null,
  meal_type text not null,
  servings double precision not null default 1,
  date date not null,
  timestamp timestamptz not null default now()
);
alter table public.food_log enable row level security;
create policy "Users can read/write own food log" on public.food_log
  for all using (auth.uid() = user_id);

-- Meal plan menus
create table public.mess_menus (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  week_number integer not null check (week_number in (1,2,3)),
  day_of_week text not null,
  meal_type text not null,
  food_ids uuid[] not null default '{}'
);
alter table public.mess_menus enable row level security;
create policy "Users can read/write own meal plans" on public.mess_menus
  for all using (auth.uid() = user_id);

-- Weight log
create table public.weight_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  weight double precision not null,
  date date not null,
  created_at timestamptz default now()
);
alter table public.weight_log enable row level security;
create policy "Users can read/write own weight log" on public.weight_log
  for all using (auth.uid() = user_id);
```

---

## Default Targets

Default targets are set for a moderate calorie deficit. Goals are fully editable in the Profile tab.

| Macro | Target |
|---|---|
| Calories | 1,800 kcal |
| Protein | 120 g |
| Carbs | 200 g |
| Fat | 55 g |

---

## Rotating Menu Cycle

The app supports a 3-week rotating meal plan. The `WeekResolver` utility handles all date arithmetic automatically, so the correct week's menu is always shown.

---

## Color Palette

| Role | Hex |
|---|---|
| Primary Green | `#4CAF50` |
| Secondary Green | `#81C784` |
| Protein (blue) | `#42A5F5` |
| Carbs (orange) | `#FFA726` |
| Fat (yellow) | `#FFEE58` |
| Dark background | `#121212` |
| Dark surface | `#1E1E1E` |

---

## License

MIT
