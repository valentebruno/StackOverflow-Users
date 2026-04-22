import UIKit

// MARK: - SplashViewController

@MainActor
final class SplashViewController: UIViewController {

    var onFinish: (() -> Void)?

    private let displayDuration: TimeInterval
    private var didScheduleFinish = false

    private let logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "LaunchLogo"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.accessibilityLabel = "Stack Overflow"
        return imageView
    }()

    init(displayDuration: TimeInterval = 0.55) {
        self.displayDuration = displayDuration
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scheduleFinishIfNeeded()
    }

    private func setupLayout() {
        view.addSubview(logoImageView)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 259),
            logoImageView.heightAnchor.constraint(equalToConstant: 148)
        ])
    }

    private func scheduleFinishIfNeeded() {
        guard !didScheduleFinish else { return }
        didScheduleFinish = true

        Task { [weak self, displayDuration] in
            try? await Task.sleep(nanoseconds: UInt64(displayDuration * 1_000_000_000))
            self?.onFinish?()
        }
    }
}
