# DTViewStack

Stack two views like the Apple Maps app

```swift
GeometryReader { geoMap in
    DTViewStack(geo: geoMap) {
        Map(coordinateRegion: $region)
    } secondary: {
        Text("Hello world")
    } toolbar: {
        HStack {
            Button("Add") { }
        }
    }
}
```
