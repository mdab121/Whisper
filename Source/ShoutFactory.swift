import UIKit

//Co za kotlet.
//let shoutView = ShoutView()

//Kolejny kotlet
//public func shout(announcement: Announcement, to: UIViewController, completion: (() -> ())? = {}) {
//  shoutView.craft(announcement, to: to, completion: completion)
//}

public final class ShoutView: UIView {
  
  public class func shout(_ announcement: Announcement, to: UIViewController, completion: (() -> ())? = {}) {
    ShoutView().craft(announcement, to: to, completion: completion)
  }
	
	fileprivate let animationDuration: TimeInterval = 0.3

  public struct Dimensions {
    public static let indicatorHeight: CGFloat = 4
    public static let indicatorWidth: CGFloat = 29
    public static let imageSize: CGFloat = 48
    public static let imageOffset: CGFloat = 18
    public static var height: CGFloat = UIApplication.shared.isStatusBarHidden ? 70 : 84
    public static var textOffset: CGFloat = 75
	public static var textMargin: CGFloat = 18
	public static let touchDraggerPadding: CGFloat = 5.0
	public static let lineHeight: CGFloat = 1.0
  }

  public fileprivate(set) lazy var backgroundView: UIView = {
    let view = UIView()
    view.backgroundColor = ColorList.Shout.background
    view.alpha = 0.98
    view.clipsToBounds = true

    return view
    }()

	public fileprivate(set) lazy var lineView: UIView = {
		let view = UIView()
		view.backgroundColor = ColorList.Shout.line
		view.isUserInteractionEnabled = false
		
		return view
	}()

  public fileprivate(set) lazy var gestureContainer: UIView = {
    let view = UIView()
    view.isUserInteractionEnabled = true

    return view
    }()

  public fileprivate(set) lazy var indicatorView: UIView = {
    let view = UIView()
    view.backgroundColor = ColorList.Shout.dragIndicator
    view.layer.cornerRadius = Dimensions.indicatorHeight / 2
    view.isUserInteractionEnabled = true

    return view
    }()

  public fileprivate(set) lazy var imageView: UIImageView = {
    let imageView = UIImageView()
    return imageView
    }()

  public fileprivate(set) lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.font = FontList.Shout.title
    label.textColor = ColorList.Shout.title
    label.numberOfLines = 2

    return label
    }()

  public fileprivate(set) lazy var subtitleLabel: UILabel = {
    let label = UILabel()
    label.font = FontList.Shout.subtitle
    label.textColor = ColorList.Shout.subtitle
    label.numberOfLines = 2

    return label
    }()

  public fileprivate(set) lazy var tapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
    let gesture = UITapGestureRecognizer()
    gesture.addTarget(self, action: #selector(ShoutView.handleTapGestureRecognizer))

    return gesture
    }()

  public fileprivate(set) lazy var panGestureRecognizer: UIPanGestureRecognizer = { [unowned self] in
    let gesture = UIPanGestureRecognizer()
    gesture.addTarget(self, action: #selector(ShoutView.handlePanGestureRecognizer))

    return gesture
    }()

  public fileprivate(set) var announcement: Announcement?
  public fileprivate(set) var displayTimer: Timer?
  public fileprivate(set) var shouldSilent = false
  public fileprivate(set) var completion: (() -> ())?

  // MARK: - Initializers

  public override init(frame: CGRect) {
    super.init(frame: frame)

    addSubview(backgroundView)
    [indicatorView, imageView, titleLabel, subtitleLabel, gestureContainer, lineView].forEach {
      backgroundView.addSubview($0) }

    clipsToBounds = false
    isUserInteractionEnabled = true
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOffset = CGSize(width: 0, height: 0.5)
    layer.shadowOpacity = 0.1
    layer.shadowRadius = 0.5

    addGestureRecognizer(tapGestureRecognizer)
    gestureContainer.addGestureRecognizer(panGestureRecognizer)

    NotificationCenter.default.addObserver(self, selector: #selector(ShoutView.orientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
  }

  // MARK: - Configuration

  public func craft(_ announcement: Announcement, to: UIViewController, completion: (() -> ())?) {
    Dimensions.height = UIApplication.shared.isStatusBarHidden ? 70 : 84

    shouldSilent = false
    configureView(announcement)
    shout(to: to)

    self.completion = completion
  }

  public func configureView(_ announcement: Announcement) {
    self.announcement = announcement
    imageView.image = announcement.image
    titleLabel.text = announcement.title
    subtitleLabel.text = announcement.subtitle

    displayTimer?.invalidate()
    displayTimer = Timer.scheduledTimer(timeInterval: announcement.duration,
      target: self, selector: #selector(ShoutView.displayTimerDidFire), userInfo: nil, repeats: false)

    setupFrames()
  }

  public func shout(to controller: UIViewController) {
    let width = UIScreen.main.bounds.width
    controller.view.addSubview(self)

    frame = CGRect(x: 0, y: -Dimensions.height, width: width, height: Dimensions.height)
    backgroundView.frame = CGRect(x: 0, y: 0, width: width, height: Dimensions.height)
	
	UIView.animate(withDuration: animationDuration, delay: 0.0, options: [.curveEaseOut], animations: {
		self.frame.origin = CGPoint.zero
		}, completion: nil)
  }

  // MARK: - Setup

  public func setupFrames() {
    let totalWidth = UIScreen.main.bounds.width
    let offset: CGFloat = UIApplication.shared.isStatusBarHidden ? 2.5 : 10
    let textOffsetX: CGFloat = imageView.image != nil ? Dimensions.textOffset : 18
	let textMargin: CGFloat = Dimensions.textMargin
	let imageSize: CGSize = imageView.image?.size ?? CGSize.zero
    let lineHeight: CGFloat = Dimensions.lineHeight
	let touchDraggerPadding: CGFloat = Dimensions.touchDraggerPadding

    backgroundView.frame.size = CGSize(width: totalWidth, height: Dimensions.height)
    lineView.frame = CGRect(origin: CGPoint(x: 0, y: backgroundView.bounds.size.height - lineHeight), size: CGSize(width: backgroundView.bounds.size.width, height: lineHeight))
    gestureContainer.frame = CGRect(x: 0, y: Dimensions.height - 20, width: totalWidth, height: 20)
    indicatorView.frame = CGRect(x: (totalWidth - Dimensions.indicatorWidth) / 2,
      y: Dimensions.height - Dimensions.indicatorHeight - touchDraggerPadding, width: Dimensions.indicatorWidth, height: Dimensions.indicatorHeight)

    imageView.frame = CGRect(x: Dimensions.imageOffset, y: (Dimensions.height - imageSize.height) / 2 + offset,
      width: imageSize.width, height: imageSize.height)

    [titleLabel, subtitleLabel].forEach {
      $0.frame.size.width = totalWidth - imageSize.width - Dimensions.imageOffset - textMargin
      $0.sizeToFit()
    }

	let accumulatedTextsHeight = titleLabel.frame.height + subtitleLabel.frame.height
    let textOffsetY = imageView.image != nil ? imageView.frame.midY - accumulatedTextsHeight * 0.5 : textOffsetX

    titleLabel.frame.origin = CGPoint(x: imageView.frame.maxX + textMargin, y: textOffsetY)
    subtitleLabel.frame.origin = CGPoint(x: imageView.frame.maxX + textMargin, y: titleLabel.frame.maxY - 1.0)

    if subtitleLabel.text?.isEmpty ?? true {
      titleLabel.center.y = imageView.center.y - 2.5
    }
  }

  // MARK: - Actions

  public func silent() {
	displayTimer?.invalidate()
	UIView.animate(withDuration: animationDuration, delay: 0.0, options: [.curveEaseIn], animations: {
		self.frame.origin.y = -Dimensions.height
		self.frame.size.height = Dimensions.height
		}, completion: { finished in
			self.completion?()
			self.removeFromSuperview()
	})
  }

  // MARK: - Timer methods

  public func displayTimerDidFire() {
    shouldSilent = true

    silent()
  }

  // MARK: - Gesture methods

  @objc fileprivate func handleTapGestureRecognizer() {
    guard let announcement = announcement else { return }
    announcement.action?()
    silent()
  }

  @objc fileprivate func handlePanGestureRecognizer() {
    let translation = panGestureRecognizer.translation(in: self)
    var duration: TimeInterval = 0
	self.displayTimer?.invalidate()

    if panGestureRecognizer.state == .changed || panGestureRecognizer.state == .began {
      if translation.y >= 12 {
        frame.size.height = Dimensions.height + 12 + (translation.y) / 25
      } else {
        frame.size.height = Dimensions.height + translation.y
      }
	  let difference = frame.size.height - Dimensions.height
	  frame.size.height = max(frame.size.height, Dimensions.height)
	  frame.origin.y = min(0, difference)
    } else {
      let height = translation.y < -5 || shouldSilent ? 0 : Dimensions.height

      duration = animationDuration * TimeInterval(frame.size.height / Dimensions.height)
	  panGestureRecognizer.view?.removeGestureRecognizer(panGestureRecognizer)
      UIView.animate(withDuration: duration, animations: {
        self.frame.size.height = height
		self.frame.origin.y = -Dimensions.height
        }, completion: { _ in  self.completion?(); self.removeFromSuperview() })
    }

    UIView.animate(withDuration: duration, animations: {
      self.backgroundView.frame.size.height = self.frame.height
	  self.lineView.frame = CGRect(origin: CGPoint(x: 0, y: self.backgroundView.bounds.size.height - Dimensions.lineHeight), size: CGSize(width: self.backgroundView.bounds.size.width, height: Dimensions.lineHeight))
      self.gestureContainer.frame.origin.y = self.frame.height - 20
      self.indicatorView.frame.origin.y = self.frame.height - Dimensions.indicatorHeight - Dimensions.touchDraggerPadding
    })
  }


  // MARK: - Handling screen orientation

  func orientationDidChange() {
    setupFrames()
  }
}
