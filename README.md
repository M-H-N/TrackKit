# TrackKit

**TrackKit** is a lightweight, flexible Swift library for managing events, triggers, and conditional logic. It simplifies workflows like feature rollouts, user prompts, promotions, or other recurring and time-based conditions, making your app logic easier to manage and maintain.

---

## When Should You Use TrackKit?

Here are some example scenarios where **TrackKit** can help developers in their daily work:

- **Showing Promotions**: You want to display a promotional message to a user, but only if:
  - They haven’t seen it in the last 24 hours.
  - They haven’t dismissed it more than 5 times.
  - They have a 50% chance of being eligible (e.g., for A/B testing).

- **Managing Daily Rewards**: In a gaming or productivity app, you need to manage daily rewards:
  - Ensure users can only claim the reward once per day.
  - Reset eligibility after 24 hours.

- **Feature Rollouts and Experimentation**: Gradually roll out a new feature to 20% of your users:
  - Assign users a probability for receiving the feature.
  - Track how many times the feature has been accessed.

- **User Engagement Events**: Control how frequently users are shown engagement events like surveys, notifications, or onboarding tutorials:
  - Display a survey only once every 7 days.
  - Ensure a welcome message is only shown once.

---

## Features

- Configurable **events** with:
  - Minimum intervals between activations
  - Expiration dates
  - Maximum activation counts
  - Priorities for sorting eligible events
  - Probability-based eligibility
  - Event dependencies for sequential activation
- **Customizable storage backends** via the `TKEventStorage` protocol.
- Default **`UserDefaults`-based storage** included.
- **Robust error handling** with descriptive error messages.
- Fully supports **async/await** for modern Swift development.
- **Combine publisher** for event activation monitoring.

---

## Installation

### Swift Package Manager (SPM)
Add the following line to your `Package.swift` file:

```swift
.package(url: "https://github.com/M-H-N/TrackKit", from: "1.0.0")
```

## Quick Start

### 1. Create an Event Configuration
Use the `TKEventConfigBuilder` to define your event:

```swift
import TrackKit

let eventConfig = TKEventConfigBuilder()
    .setId("daily_bonus")
    .setMinInterval(24 * 60 * 60) // 1 day
    .setExpirationDate(Date().addingTimeInterval(7 * 24 * 60 * 60)) // Expires in 7 days
    .setMaxActivationCount(5) // Maximum of 5 activations
    .setPriority(10) // Higher priority for sorting eligible events
    .setProbability(0.8) // 80% chance of eligibility
    .setMetadata(["description": "Daily Bonus Reward"])
    .setDependencies(["tutorial_completed", "level_5_reached"]) // Only eligible after completing tutorial and reaching level 5
    .build()
```

### 2. Initialize the Event Manager

Create a `TKEventManager` with the default storage or your own custom implementation.

### Using Default Storage
```swift
// Uses UserDefaults storage by default
let eventManager = TKEventManager()
```

### Using `UserDefaults` Storage Explicitly
```swift
let storage = TKUserDefaultsStorage()
let eventManager = TKEventManager(storage: storage)
```

### Using Custom Storage

Implement the `TKEventStorage` protocol to use a different backend, such as Core Data or a cloud database:

```swift
class MyCustomStorage: TKEventStorage {
    func set<T: Codable>(_ value: T, forKey key: String) throws { 
        /* Custom logic */ 
    }
    func get<T: Codable>(forKey key: String) throws -> T? { 
        /* Custom logic */ 
    }
    func remove(forKey key: String) throws { 
        /* Custom logic */ 
    }
}
let customStorage = MyCustomStorage()
let eventManager = TKEventManager(storage: customStorage)
```

### 3. Check and Activate Events

### Checking Eligibility

```swift
do {
    if try await eventManager.canActivateEvent(config: eventConfig) {
        print("Event is eligible: \(eventConfig.id)")
        try await eventManager.markEventAsActivated(id: eventConfig.id)
    } else {
        print("Event is not eligible: \(eventConfig.id)")
    }
} catch let error as TKEventError {
    print("Error occurred: \(error)")
} catch {
    print("Unexpected error: \(error)")
}
```

### Fetching Eligible Events

```swift
let configs = [eventConfig, anotherEventConfig]
do {
    let eligibleEvents = try await eventManager.getEligibleEvents(configs: configs)
    for event in eligibleEvents {
        print("Eligible event: \(event.id)")
    }
} catch {
    print("Error fetching eligible events: \(error)")
}
```

## Advanced Usage

### Event Publishers

TrackKit provides a Combine publisher to monitor event activations in real-time. This is useful for analytics, UI updates, or triggering dependent actions:

```swift
// Subscribe to event activations
let cancellable = eventManager.eventActivations
    .sink { activation in
        print("Event \(activation.eventId) activated at \(activation.activationDate)")
        print("Total activations: \(activation.activationCount)")
    }

// Example: Update UI when specific events are activated
let uiUpdates = eventManager.eventActivations
    .filter { $0.eventId == "feature_unlock" }
    .sink { activation in
        DispatchQueue.main.async {
            updateUIForFeatureUnlock()
        }
    }

// Example: Track analytics for all event activations
let analytics = eventManager.eventActivations
    .sink { activation in
        Analytics.shared.track(
            event: "event_activated",
            properties: [
                "event_id": activation.eventId,
                "activation_count": activation.activationCount
            ]
        )
    }
```

### Event Dependencies

Events can be configured to depend on other events being activated first. This is useful for creating sequential workflows or unlocking features based on user progress:

```swift
// Create a bonus round event that requires level 10 completion
let bonusRound = TKEventConfigBuilder()
    .setId("bonus_round")
    .setDependencies(["level_10_completed"]) // Requires "level_10_completed" to be activated
    .setProbability(1.0)
    .setMetadata(["title": "Bonus Round Unlocked!"])
    .build()

// The bonus round will only be eligible after level 10 is completed
if try await eventManager.canActivateEvent(config: bonusRound) {
    print("Unlock Bonus Round!")
    try await eventManager.markEventAsActivated(id: bonusRound.id)
}

// Example: Survey that appears only after a promotion has been shown
let postPromotionSurvey = TKEventConfigBuilder()
    .setId("post_promo_survey")
    .setDependencies(["summer_promotion"])
    .setMinInterval(24 * 60 * 60) // Wait 24 hours after promotion
    .setProbability(0.5) // Show to 50% of eligible users
    .build()
```

### Custom Conditions

Pass a custom condition closure to `canActivateEvent` to evaluate additional logic:

```swift
let customConditions: [String: () throws -> Bool] = [
    "daily_bonus": { return Calendar.current.isDateInWeekend(Date()) }
]

do {
    let eligibleEvents = try await eventManager.getEligibleEvents(configs: configs, customConditions: customConditions)
    for event in eligibleEvents {
        print("Eligible event on weekends: \(event.id)")
    }
} catch {
    print("Error fetching eligible events: \(error)")
}
```

## Error Handling

TrackKit uses `TKEventError` for clear error reporting:

- **`.valueNotFound(String)`**: Thrown when a requested key does not exist in storage.
- **`.serializationFailed(String)`**: Thrown when encoding or decoding a value fails.
- **`.invalidProbability(String)`**: Thrown when a probability value is out of range (0.0–1.0).

```swift
do {
    try await eventManager.resetEvent(id: "unknown_event")
} catch let error as TKEventError {
    switch error {
    case .valueNotFound(let key):
        print("Value not found for key: \(key)")
    case .serializationFailed(let message):
        print("Serialization error: \(message)")
    case .invalidProbability(let message):
        print("Invalid probability: \(message)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```
---

## Example Use Cases

### 1. Achievement System with Dependencies

Create a tiered achievement system where rewards unlock sequentially:
```swift
// Define the achievements chain
let bronzeAchievement = TKEventConfigBuilder()
    .setId("bronze_achievement")
    .setProbability(1.0)
    .setMetadata([
        "title": "Bronze Warrior",
        "reward": "100 coins"
    ])
    .build()

let silverAchievement = TKEventConfigBuilder()
    .setId("silver_achievement")
    .setDependencies(["bronze_achievement"]) // Requires bronze first
    .setProbability(1.0)
    .setMetadata([
        "title": "Silver Warrior",
        "reward": "500 coins"
    ])
    .build()

let goldAchievement = TKEventConfigBuilder()
    .setId("gold_achievement")
    .setDependencies(["silver_achievement"]) // Requires silver first
    .setProbability(1.0)
    .setMetadata([
        "title": "Gold Warrior",
        "reward": "2000 coins"
    ])
    .build()

// Subscribe to achievement unlocks to show notifications
let achievementNotifications = eventManager.eventActivations
    .sink { activation in
        guard let achievement = [bronzeAchievement, silverAchievement, goldAchievement]
            .first(where: { $0.id == activation.eventId }) else { return }
        
        showAchievementPopup(
            title: achievement.metadata?["title"] as? String ?? "",
            reward: achievement.metadata?["reward"] as? String ?? ""
        )
    }

// Check and award achievements
if try await eventManager.canActivateEvent(config: bronzeAchievement) {
    try await eventManager.markEventAsActivated(id: bronzeAchievement.id)
}
```

### 2. Onboarding Flow with Feature Unlocks

Guide users through a sequential onboarding process, unlocking features as they progress:
```swift
// Define onboarding steps
let welcomeStep = TKEventConfigBuilder()
    .setId("welcome_completed")
    .setMaxActivationCount(1) // Only show once
    .build()

let profileStep = TKEventConfigBuilder()
    .setId("profile_completed")
    .setDependencies(["welcome_completed"])
    .setMaxActivationCount(1)
    .build()

let featureIntroStep = TKEventConfigBuilder()
    .setId("feature_intro_completed")
    .setDependencies(["profile_completed"])
    .setMaxActivationCount(1)
    .build()

// Premium features only available after onboarding
let premiumFeature = TKEventConfigBuilder()
    .setId("premium_feature")
    .setDependencies(["feature_intro_completed"])
    .setProbability(0.5) // A/B test with 50% of users
    .build()

// Track onboarding progress
let onboardingProgress = eventManager.eventActivations
    .sink { activation in
        switch activation.eventId {
        case "welcome_completed":
            showProfileSetupScreen()
        case "profile_completed":
            showFeatureIntroduction()
        case "feature_intro_completed":
            showCompletionCelebration()
            checkPremiumFeatureEligibility()
        default:
            break
        }
    }
```

### 3. Seasonal Promotion Campaign

Run a holiday promotion campaign with time-based offers and tracking:
```swift
let blackFridayDeal = TKEventConfigBuilder()
    .setId("black_friday_deal")
    .setExpirationDate(Calendar.current.date(from: DateComponents(year: 2024, month: 11, day: 24)))
    .setMaxActivationCount(1)
    .setMetadata([
        "discount": "50% off",
        "code": "BF2024"
    ])
    .build()

let cyberMondayDeal = TKEventConfigBuilder()
    .setId("cyber_monday_deal")
    .setDependencies(["black_friday_deal"]) // Only show after Black Friday
    .setExpirationDate(Calendar.current.date(from: DateComponents(year: 2024, month: 11, day: 27)))
    .setMaxActivationCount(1)
    .setMetadata([
        "discount": "40% off",
        "code": "CM2024"
    ])
    .build()

// Track promotion engagement
let promotionAnalytics = eventManager.eventActivations
    .sink { activation in
        Analytics.shared.track(
            name: "promotion_viewed",
            properties: [
                "promotion_id": activation.eventId,
                "view_count": activation.activationCount,
                "timestamp": activation.activationDate
            ]
        )
    }

// Check and display current promotion
if try await eventManager.canActivateEvent(config: blackFridayDeal) {
    showPromotionBanner(
        discount: blackFridayDeal.metadata?["discount"] as? String ?? "",
        code: blackFridayDeal.metadata?["code"] as? String ?? ""
    )
    try await eventManager.markEventAsActivated(id: blackFridayDeal.id)
}
```

These examples demonstrate how to:
- Create sequential achievement systems with dependencies
- Build guided onboarding flows that unlock features
- Manage seasonal promotions with analytics tracking
- Use publishers to respond to events in real-time
- Combine multiple TrackKit features for complex scenarios

---

## Contributing

We welcome contributions! To contribute:

1. Fork this repository.
2. Create a new branch with your feature or bug fix.
3. Submit a pull request.

For major changes, please open an issue to discuss your ideas first.

---

## License

TrackKit is licensed under the MIT License. You are free to use, modify, and distribute this library with attribution.

---

## Contact

If you have questions or issues, feel free to open an issue on GitHub or contact us directly.

---

## Future Features

Here are some ideas for future improvements:

- Support for logging and analytics integrations (e.g., Firebase).
- Built-in scheduling for recurring events.
- Enhanced support for multithreaded or async storage backends.
- SwiftUI components for UI-based event handling.