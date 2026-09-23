# air
`air` is a lightweight, open-source desktop dashboard that collapses your morning clutter of weather, news, to-dos, and whatever else you could imagine into a glance, solving the problem of spending too much time going through different applications for different things, hence wasting time.

Video Demo: https://streamable.com/c8mqt2

![air dashboard](screenshots/dashboard.png)

## AI Declaration

Yes, I used AI models for this project. Specifically: in-line code completions to save time, and AudioManager used Gemini to help make. I used Claude to help me research how to find CPU, GPU and some memory stats in the System Stats card, but everything else in the project was done by me.

## Credits

My project uses Kirtan Shah's [nowplaying-cli](https://github.com/kirtan-shah/nowplaying-cli) to pull metadata from macOS's Now Playing system.

## What it does
air opens a card-based dashboard so you get the important stuff quickly instead of hunting through different apps. From factory release it includes:
- Weather (current conditions and a multi-day forecast)
- News (a feed of recent international headlines)
- To-Do List (a simple task list)
- Calendar (upcoming events at a glance, pulls from Apple Calendar)
- Streak (dot based habit tracker)
- Timer (countdown/pomodoro timer)
- Clipboard (recent clipboard history, doesn't show clipboard of connected iPhone)
- Bookmarks (quick links/app shortcuts)
- Audio Player (playback controls for media)
- Speed Test (internet speed test)
- System Stats (shows system statistics)
- List Generator (generate an order of random items from a list and use rules to determine generation)
- World Clock (times around the world)
- Unit Converter (convert between different metric and imperial metrics)
- RNG Generator (generate a random number given any range)
- Public IP Viewer (view your public IPv4 and IPv6 address if availabe)
- QR Code Generator (generate a QR code from a URL)

Cards are laid out on a grid and has settings, so you can configure the dashboard to show you what you care about.

### Other features
**Temporary Cards:**
- The temporary card manager is an overlay to the normal dashboard which allows you to open a single card until you dismiss it.
- You can open the temporary card manager using `⌘ + K`.

**Spaces:**
- Spaces are separate collections of cards that you can navigate through, essentially collection profiles.
- You can navigate spaces using the default keybinds `⌘ + ([ or ])` after you have created another space in `Settings -> Spaces`
- Keybinds are configurable in `Settings -> Spaces`

## What I built
- The app, with SwiftUI
- A small custom backend that serves weather, news, and speed test data (you can wire your own api, I just made my own for testing and it will most likely be up indefinetely, I used Python and FastAPI)
## Get Started
### Requirements
- Apple Silicon (so M series) Mac
- macOS Sonoma (14)
- Associated Xcode (if you plan to build yourself)
### Run it

Get the `.dmg` from [Releases](https://github.com/dylankaru/air/releases), open it, and run the installer.
> Note: since this isn't notarised, macOS Gatekeeper might warn you on first launch, so you may need to right-click the app -> Open to bypass it.

**OR**

1. Clone the repo
```bash
git clone https://github.com/dylankaru/air.git
cd air
```
2. Open the project in Xcode
3. Build and run (`⌘R`)

## Making Your Own Card
Designing your own card is simple as it only requires basic SwiftUI knowledge.
1. Create the view. For organisation sake, add it under `air/cards` , for example `MyCard.swift`. Wrap your content in the `Card` container so that it gets the standard corner radius, background, and can be rendered on your dashboard:
```swift
   struct MyNewCard: View {
       var body: some View {
           Card {
               Text("Hey :)")
           }
       }
   }
```
2. (Optional) Add a settings view. If you design your card to be configurable, create a matching file in `air/cards/settings/`, for example `MySettingsView.swift`, following the pattern of the existing settings files.

3. When designing your cards, it would be better to follow these trends: I've saved card configuration settings to UserDefaults (so `@AppStorage`), and card data is stored using the JSONManager and written either to `.cache` or `.applicationSupport`

4. Register the card. In `ContentView.swift`, the `appCards` array is where all cards are initialised. You wrap your card with its metadata using `CardItem`. It accepts the following arguments: `key`, `title`, `icon`, `colStart`, `colEnd`, `rowStart`, `rowEnd`, `minColSpan`, `minRowSpan`, `startsVisible`, `settingsView`, and `content` (they also accept ignoreEdgePadding and ignoreStandardArrangements, but you're likely need not to use them).

```swift
CardItem(
  key: "myCard",
  title: "My Card", icon: "star.fill",
  colStart: 6, colEnd: 13, rowStart: 7, rowEnd: 10,
  settingsView: { MySettingsView() }
) {
  MyCard()
}
```
> Note: `settingsView` is only required if you pass a settings page. `startsVisible` is only added to cards that aren't apart of the original render (I should have fixed that on my part but as of version <=2.0.0 you need to pass it yourself). **ALSO**, The grid is 20 columns wide and 14 rows tall, so pick a `colStart` and `colEnd` that fits comfortably alongside existing cards within this range.

5. Build and run. Your card should appear on the dashboard immediately, and its settings (if passed) will show up in the Settings window.

## Contributing
This is a personal project, but issues and pull requests are welcome if you'd like to add a card or fix a bug.
## License
MIT
