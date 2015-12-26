# LCBarrageView

## About

LCBarrageView is a light-weight barrage(danmu) view, and you can add it on any view. It can be used to present comments or any other text content.

## Installation

Just drag the LCBarrageView class file(demo files and assets are not needed) into your project.

## How To Use

LCBarrageView provided many properties for customization, just as the demo screenshot below indicates:

![LCBarrageView](https://raw.githubusercontent.com/GavinFlying/LC-Barrage-View-Swift/master/Barrage/barrage.gif)

In LCBarrageView, the bullets of which consist the barrage is in LCBullet type:

```swift
struct LCBullet {
    var content: String?
    var color: UIColor?
    var fontSize: CGFloat?
    var attrContent: NSAttributedString?
    var bulletType: BulletType = .Roll
}
```

Each bullet should have at least a content in String type **OR** a attrContent in NSAttributedString type, if your bullet have both, LCBarrageView **will choose attrContent** to make LCBullet.

Making a array of LCBullet, and put it into LCBarrageView, do some customization if you want, then you can fire.

```swift
barrageView.processBullets(bulletsArray: commentsArray)
barrageView.bulletLabelNumber = 60 // optional, default is 30
// ...Other Customization Work...
barrageView.fire()
```

Don't forget to stop barrage when you don't need it

```swift
barrageView.stop()
```

For more details, please check the demo.


## License

LCBarrageView is available under the MIT license. See the LICENSE file for more info.
